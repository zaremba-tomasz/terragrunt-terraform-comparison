const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();

const format = require('date-format');
const random = require('randomstring');

exports.handler = async(event, context) => {
    const params = {
        TableName: process.env.DYNAMODB_TABLE_NAME,
        Item: {
            id: String(event.detail.id),
            title: random.generate({
                length: 10,
                charset: 'alphabetic',
                capitalization: 'uppercase'
            }),
            date: format.asString('dd.MM.yyyy hh:mm:ss.SSS', new Date()),
            tags: [...Array(3).keys()].map(id => random.generate({
                length: 5,
                charset: 'alphabetic',
                capitalization: 'lowercase'
            }))
        }
    };
    await dynamo.put(params).promise();

    context.succeed(event.detail);
}
