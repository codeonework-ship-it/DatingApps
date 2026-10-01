import {defineConfig} from '@playwright/test';
export default defineConfig({
  testDir:'./tests', timeout:60000, workers:1,
  reporter:[['list'],['json',{outputFile:'../qa/results/2026-09-27-website/browser-results.json'}]],
  outputDir:'../qa/results/2026-09-27-website/browser-artifacts',
  use:{actionTimeout:15000,baseURL:'http://127.0.0.1:4190', viewport:{width:1440,height:1000},
    launchOptions:{executablePath:process.env.CHROME_BIN || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'},
    screenshot:'only-on-failure', trace:'retain-on-failure'},
});
