#!/usr/bin/env node

const { readFile, readdir } = require('fs/promises');

const entries = {};

const getFiles = async (directory) => {
  const entries = await readdir(directory);
  const files = entries.filter((e) => e.match(/.+\.out$/));

  return files;
};

const entryForFile = (filename) => {
  const fileparts = filename.match(/.+\/(.+)\.out$/);
  if (!fileparts) {
    return;
  }

  const parts = fileparts[1].match(/(.+)\.sql/);
  if (!parts) {
    return fileparts[1];
  }

  return parts[1];
};

const processFile = async (filename) => {
  const entry = entryForFile(filename);
  if (!entry) {
    console.log(`Unable to parse file ${filename}`);
    return;
  }
  const data = await readFile(filename, 'utf-8');
  const lines = data.split('\n');

  let result;
  if (entries[entry]) {
    result = entries[entry]['query-time'];
  }

  for (let line of lines) {
    const parts = line.match(/Time: (\d+\.\d+)/);
    if (parts) {
      const time = Number(parts[1]);
      if (result) {
        result.count++;
        result.sum += time;
        // data and setup should use sum, not average
        if (Number.isNaN(Number(entry))) {
          result.value = result.sum;
        } else {
          result.value = result.sum / result.count;
        }
        if (time < result.lower_bound)
          result.lower_bound = time;
        if (time > result.upper_bound)
          result.upper_bound = time;
      } else {
        result = {
          count: 1,
          sum: time,
          value: time,
          lower_bound: time,
          upper_bound: time
        };
      }
    }
  }

  if (result) {
    entries[entry] = { 'query-time': result };
  }
};

const addPropertyPrefix = (obj, prefix) => {
  if (!prefix)
    return obj;

  const output = {};
  for (const key in obj) {
    output[prefix + '-' + key] = obj[key];
  }
  return output;
}

const run = async () => {
  const files = await getFiles(process.argv[2]);

  for (let file of files) {
    await processFile(`${process.argv[2]}/${file}`);
  }

  const total = { value: 0, lower_bound: 0, upper_bound: 0 }
  const queries = { value: 0, lower_bound: 0, upper_bound: 0 }
  for (const key in entries) {
    const data = entries[key]['query-time'];
    total.value += data.value;
    total.lower_bound += data.lower_bound;
    total.upper_bound += data.upper_bound;
    if (!Number.isNaN(Number(key))) {
      queries.value += data.value;
      queries.lower_bound += data.lower_bound;
      queries.upper_bound += data.upper_bound;
    }
  }
  entries.total = { 'query-time': total };
  entries.queries = { 'query-time': queries };

  const output = addPropertyPrefix(entries, process.argv[3]);

  console.log(JSON.stringify(output));
};

run();
