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

  const parts = fileparts[1].match(/(.+).sql/);
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

  for (let line of lines) {
    const parts = line.match(/Time: (\d+.\d+)/);
    if (parts) {
      const time = Number(parts[1]);
      if (entries[entry]) {
        entries[entry].count++;
        entries[entry].value += time;
      } else {
        entries[entry] = {
          count: 1,
          value: time
        };
      }
    }
  }
};

const run = async () => {
  const files = await getFiles(process.argv[2]);

  for (let file of files) {
    await processFile(`${process.argv[2]}/${file}`);
  }

  const results = {};
  results['total'] = results['queries'] = 0;
  for (const key in entries) {
    const entry = entries[key];
    const avg = entry.value / entry.count;
    results[key] = avg;
    results['total'] += avg;
    if (!Number.isNaN(Number(key))) {
      results['queries'] += avg;
    }
  }

  console.log(JSON.stringify(results));
};

run();
