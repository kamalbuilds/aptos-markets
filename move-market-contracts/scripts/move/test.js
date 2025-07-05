require("dotenv").config();

const cli = require("@aptos-labs/ts-sdk/dist/common/cli/index.js");

async function test() {
  const move = new cli.Move();

  await move.test({
    packageDirectoryPath: "move/contract",
    namedAddresses: {
      owner: "0x100",
      aptosmarkets: "0x123",
      market_admin: "0x400",
    },
    extraArguments: ['--coverage']
  });
}
test();
