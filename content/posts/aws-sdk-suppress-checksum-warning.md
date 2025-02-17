---
title: Suppress an AWS S3 SDK checksum support warning in Go
date: 2025-02-17
image: images/fritz.png
caption: What better way to illustrate a post about the tiniest of annoyances with a photo of my sleeping cat
description: Or how to become one of the few search results for this warning
tags: ['golang', 'aws', 'sdk', 's3', 'jetbrains', 'ai']
---

Today I found myself debugging a mysterious log message flooding the output of a small tool I have built to make
the life of my colleagues easier.

The full message was:

```
SDK 2025/02/17 16:36:44 WARN Response has no supported checksum. Not validating response payload.
```

~~Searching~~ Googling ["Response has no supported checksum. Not validating response payload."](https://www.google.com/search?q=%22Response+has+no+supported+checksum.+Not+validating+response+payload.%22)
revealed a shockingly low number of results (at the time of writing three, and I'm hoping to become number four)

Alas, from skimming the results, I quickly guessed (correctly) that this was caused by an innocuous function meant to
load an image or file from an S3 bucket and returning that object's bytes to the caller. I've reproduced the
function below, but stripped all the `if err != nil` goodness for brevity:

```go
package main

import (
	"context"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"io"
)

// LoadImage retrieves a file from an S3 bucket using the provided access credentials and returns its content as a byte slice.
func LoadImage(accessKeyId, secretAccessKey, region, bucket, key string) ([]byte, error) {
	cfg, _ := config.LoadDefaultConfig(context.TODO(),
		config.WithRegion(region),
		config.WithCredentialsProvider(
			credentials.NewStaticCredentialsProvider(
				accessKeyId, secretAccessKey, "",
			)),
	)

	client := s3.NewFromConfig(cfg)

	result, _ := client.GetObject(context.TODO(), &s3.GetObjectInput{
		Bucket: &bucket,
		Key:    &key,
	})
	defer result.Body.Close()

	return io.ReadAll(result.Body)
}
```

A [fruitless conversation](/text/chat-8d1d87ee-b573-46bd-a077-a359baae4ed7.md) with the Jetbrains AI later, I managed
to figure out the solution myself:

```go
	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.DisableLogOutputChecksumValidationSkipped = true
	})
```

In plain English, when constructing the S3 client, pass an option function and set the option 
`DisableLogOutputChecksumValidationSkipped` to `true`.

And voilà, the warning is gone!