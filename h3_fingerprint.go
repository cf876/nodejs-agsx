package main

import (
	"crypto/sha256"
	"crypto/tls"

	//	"crypto/x509"
	//"encoding/hex"
	"fmt"
	"log"
	"net/http"

	"github.com/quic-go/quic-go/http3"
)

func main() {
	// 目标网站，请确保它支持 HTTP/3
	// 像 google.com, cloudflare.com, facebook.com 等都支持
	targetURL := "https://51.83.6.7:20143"
	sniServerName := "www.bing.com"
	// 1. 创建一个 HTTP/3 的 RoundTripper
	// RoundTripper 是一个接口，用于执行单个 HTTP 事务，

	tlsConfig := &tls.Config{
		InsecureSkipVerify: true,
		ServerName:         sniServerName,
	}
	// http3.RoundTripper 实现了 HTTP/3 协议。
	roundTripper := &http3.Transport{

		TLSClientConfig: tlsConfig,
	} //RoundTripper{}

	// 2. 创建一个 HTTP 客户端，并设置其 Transport 为我们创建的 http3.RoundTripper
	client := &http.Client{
		Transport: roundTripper,
	}

	// 3. 创建一个新的 HTTP 请求
	// 使用 HEAD 请求可以减少数据传输，因为我们只需要连接信息
	req, err := http.NewRequest("HEAD", targetURL, nil)
	if err != nil {
		log.Fatalf("创建请求失败: %v", err)
	}

	fmt.Printf("正在通过 HTTP/3 连接到 %s...\n", targetURL)

	// 4. 发起请求
	resp, err := client.Do(req)
	if err != nil {
		log.Fatalf("请求失败: %v", err)
	}
	defer resp.Body.Close()

	// 5. 从响应中获取 TLS 连接状态
	// 对于 HTTP/3，这个信息是可用的
	tlsState := resp.TLS
	if tlsState == nil {
		log.Fatal("无法获取 TLS 连接状态，可能不是 HTTPS 连接。")
	}

	// 6. 获取服务器的证书链
	// PeerCertificates[0] 是叶子证书，也就是服务器本身的证书
	if len(tlsState.PeerCertificates) == 0 {
		log.Fatal("服务器未提供任何证书。")
	}
	serverCert := tlsState.PeerCertificates[0]
	//	pubKeyBytes, err := x509.MarshalPKIXPublicKey(serverCert.PublicKey)
	//	if err != nil {
	//		log.Fatalf("Failed to marshal public key: %v", err)
	//	}

	//	fingerprint := sha256.Sum256(pubKeyBytes)
	//#fingerprintBase64 := base64.StdEncoding.EncodeToString(fingerprint[:])

	//	fmt.Printf("Certificate Public Key SHA256 Fingerprint : %s\n", fingerprint)

	// 7. 计算证书的 SHA256 指纹
	// 我们使用证书的原始 DER 编码数据进行哈希
	var fingerprint [32]byte = sha256.Sum256(serverCert.Raw)

	// 8. 格式化并打印结果
	// %x 会将字节切片格式化为小写的十六进制字符串
	fmt.Println("连接成功！")
	fmt.Printf("服务器证书通用名称: %s\n", serverCert.Subject.CommonName)
	fmt.Printf("证书 SHA256 指纹: %x\n", fingerprint)
}