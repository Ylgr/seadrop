const fs = require('fs');
console.log('Starting URI Generator');
function createData(id) {return({
    "tokenId": id,
    "name": `Dice Bear #${id}`,
    "description": "Just a test NFT",
    "image": `https://api.dicebear.com/7.x/adventurer/svg?seed=beincom-test${id}`,
    "attributes": []
})}
const runner = [];
console.log('Creating 100 URIs')

for (let i = 0; i < 30; i++) {
    console.log(`Creating ${i}`)
    console.log(JSON.stringify(createData(i)))
    fs.writeFile(`./uri/${i}.json`, JSON.stringify(createData(i)), function (error) {})
}
