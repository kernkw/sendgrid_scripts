package main

import (
	"encoding/csv"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strings"
)

// Dedups csv by email column header
// Author: Kyle Kern
// Date: 11/25/2015
//
// CLI Running Instructions:
//   $  go build dedup_csv.go
//   $  ./dedup_csv "in/filepath.csv" "out/filepath.csv"

func main() {

	originalFilepath := os.Args[1]
	dedupedFilepath := os.Args[2]

	csvfile, err := os.Open(originalFilepath)
	if err != nil {
		fmt.Println(err)
	}

	buffer, _ := ioutil.ReadAll(csvfile)
	rx := strings.NewReplacer("\r\n", "\n", "\r", "\n")

	reader := csv.NewReader(strings.NewReader(rx.Replace(string(buffer))))

	header, err := reader.Read()
	if err != nil {
		fmt.Println("cant read header")
	}

	cols := make(map[string]int)
	for i, col := range header {
		col = strings.ToLower(col)
		cols[col] = i
	}

	if _, ok := cols["email"]; ok {
	} else {
		fmt.Println("expected CSV to contain email field")
	}

	defer csvfile.Close()

	outFile, err := os.Create(dedupedFilepath)
	if err != nil {
		fmt.Println(err)
	}
	defer outFile.Close()

	w := csv.NewWriter(outFile)

	m := make(map[string][]string)
	for {
		record, err := reader.Read()
		// end-of-file is fitted into err
		if err == io.EOF {
			break
		} else if err != nil {
			fmt.Println("Error:", err)
		}

		if len(record) <= 1 {
			fmt.Println("error parsing csv, whole csv is on one line")
		}
		email := record[cols["email"]]
		m[email] = record
	}

	for _, v := range m {
		w.Write(v)
	}
	w.Flush()
}
