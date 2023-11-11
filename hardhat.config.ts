import * as dotenv from 'dotenv';

import { HardhatUserConfig, task } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-contract-sizer';
import 'hardhat-gas-reporter';
import '@openzeppelin/hardhat-upgrades';
import 'hardhat-abi-exporter';
import fs from 'fs';
import path from 'path';

dotenv.config();

const env = {
  privateKey: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
};

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.20',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      accounts: {
        accountsBalance: '100000000000000000000000', // 100,000 ETH
      },
    },
    dev: {
      url: 'http://localhost:8545',
    },
    'opbnb-testnet': {
      url: 'https://opbnb-testnet-rpc.bnbchain.org',
      accounts: env.privateKey,
      chainId: 5_611,
      gasPrice: 1500000008,
    },
  },
  contractSizer: {
    runOnCompile: true,
  },
  gasReporter: {
    enabled: true,
  },
  // https://www.npmjs.com/package/hardhat-abi-exporter
  abiExporter: {
    path: path.join(__dirname, './abi-types'),
    runOnCompile: true,
    clear: true,
    except: [], // ''
    rename: (sourceName: string, name: string) => {
      return `${sourceName.replace(/\.sol$/, '')}/${name}`;
    },
  },
};

export default config;

// override the ABI export task defined by the plugin
task('export-abi-group').setAction(async (args, hre, runSuper) => {
  // call super to avoid overwriting funtionality
  await runSuper();

  // rename the exported files to .ts
  async function resetFiles(dir: string) {
    const files = await fs.promises.readdir(dir);
    const pending = files.map(async (item) => {
      const filePath = path.join(dir, item);
      const stat = fs.lstatSync(filePath);
      if (stat.isDirectory() === true) return resetFiles(filePath);
      if (filePath.endsWith('.json') === false) return;
      let content = await fs.promises.readFile(filePath, 'utf8');
      try {
        content = JSON.stringify(JSON.parse(content), null, 2);
      } catch (e) {
        console.error('Error parsing JSON', filePath, content);
        throw e;
      }
      const fileName = path.basename(filePath, '.json');
      const newContent = `const ${fileName} = ${content} as const;\nexport { ${fileName} };\n`;
      await fs.promises.writeFile(filePath.replace(/contracts\/(.*)\/(.*).json$/, '$2.ts'), newContent, 'utf8');
      await fs.promises.unlink(filePath);
    });
    await Promise.all(pending);
  }
  await resetFiles(args.abiGroupConfig.path);
});