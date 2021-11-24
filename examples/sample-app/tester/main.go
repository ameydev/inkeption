package main

import (
	"bytes"
	"fmt"
	"log"
	"net/http"
)

func main() {
	baseULR := "http://localhost:30080/"
	url := baseULR + "book/"
	fmt.Println("Starting testing URL:>", url)
	testGetData(url)
	testPostData(url)
}

func testPostData(url string) {
	fmt.Println("Testing POST response")
	var jsonStr = []byte(`{
		"name": "Golang Hacks",
		"author": "Mr. Golang Expert",
		"publication": "sample"
	}`)
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonStr))
	req.Header.Set("X-Custom-Header", "myvalue")
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()

	fmt.Println("response Status:", resp.Status)
	// body, _ := ioutil.ReadAll(resp.Body)
	// fmt.Println("response Body:", string(body))

}

func testGetData(url string) {
	fmt.Println("Testing GET response")
	resp, err := http.Get(url)

	if err != nil {
		log.Fatal(err)
	}

	defer resp.Body.Close()

	// body, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("response Status:", resp.Status)

	// fmt.Println(string(body))
}
