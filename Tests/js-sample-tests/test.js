const { getSignedUrl, S3RequestPresigner } = require("@aws-sdk/s3-request-presigner");
const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");	
const { parseUrl } = require("@aws-sdk/url-parser");
const { fromEnv } = require("@aws-sdk/credential-providers");
const { Hash } = require("@aws-sdk/hash-node");
const { HttpRequest } = require("@aws-sdk/protocol-http");
const { formatUrl } = require("@aws-sdk/util-format-url");
const MockDate = require('mockdate');

// Test Setup – these values match the ones used the Swift test cases
process.env["AWS_ACCESS_KEY_ID"] = "AKIATNTB7DC3QVYVRJ2Y"
process.env["AWS_SECRET_ACCESS_KEY"] = "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"
MockDate.set(new Date(1440959760 * 1000))

const bucket = "test-bucket"
const region = "us-east-1"
const key = "test-key"

// Test Code
const client = new S3Client({region: region, useAccelerateEndpoint: true});
const command = new GetObjectCommand({
  Bucket: bucket,
  Key: key,
});

getSignedUrl(client, command, { expiresIn: 3600 }).then((url) => {
	console.log(url);
	console.log("PRESIGNED URL: ", formatUrl(url));
});
