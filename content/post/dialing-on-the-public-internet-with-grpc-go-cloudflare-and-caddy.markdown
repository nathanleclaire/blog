---
title: Dialing on the Public Internet With gRPC-Go, Cloudflare, and Caddy
layout: post
date: 2023-01-10T17:38:28.209Z
categories:
  - programming
---
``` ``
$ amostra work https://grpc.domain.com
FATA[2023-01-10T17:43:00Z] ../worker.go:146 failed to call schedule client allocs: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing dial tcp: lookup tcp///grpc.100brushes.com: Servname not supported for ai_socktype"```

E﻿nable support buried deep in menu in https://support.cloudflare.com/hc/en-us/articles/360050483011-Understanding-Cloudflare-gRPC-support 

C﻿addy config:

``` ``
g﻿rpc.domain.com {
        reverse_proxy h2c://127.0.0.1:42000
}```﻿

``` ``
$ amostra work grpc.100brushes.com:443                         
FATA[2023-01-10T17:34:01Z] ../worker.go:138 failed to call schedule client allocs: rpc error: code = Unavailable desc = conne
ction error: desc = "error reading server preface: http2: frame too large"```﻿

N﻿eeded to get system certs

`﻿diff

* ```
    systemCertPool, err := x509.SystemCertPool()
  ```
* ```
    if err != nil {
  ```
* ```
            log.Fatal("can't get system cert pool", err)
  ```
* ```
    }
    grpc.UseCompressor(gzip.Name)
  ```
* ```
    conn, err := grpc.Dial(cliCtx.Args().Get(0), grpc.WithTransportCredentials(insecure.NewCredentials()))
  ```
* ```
    conn, err := grpc.Dial(cliCtx.Args().Get(0), grpc.WithTransportCredentials(credentials.NewTLS(&tls.Config{
  ```
* ```
            RootCAs: systemCertPool,
  ```
* ```
    })))
      if err != nil {
              logrus.Fatalf("fail to dial: %v", err)
      }
  ```

  `﻿

``` ``
$ amostra work dns:///dev.100brushes.com
.﻿.. Connected and ready to work ...```