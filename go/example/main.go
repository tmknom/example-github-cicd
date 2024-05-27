package main

import "fmt"

var version string // ビルド時にldflagsフラグ経由でバージョンを埋め込むための変数

func main() {
	fmt.Printf("Example %s\n", version)
}
