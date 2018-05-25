package main

import (
	"flag"
	"fmt"
	"github.com/mapbox/planet-stream/streams"
	"log"
	"os"
	"os/exec"
	"path"
	"strings"
	"sync"
	"time"
	"runtime/debug"
)

func check(e error) {
	if e != nil {
		debug.PrintStack()
		log.Fatal(e)
	}
}

// Downloads a PBF file while importing it in chunks.
//
// Waits for the import process to complete because that tends to be the
// the bottleneck for this particular use case.
func main() {
	locPtr := flag.String("i", "", "input file or URL")
	tmpPtr := flag.String("t", "/tmp", "temporary path for file chunks")
	cmdPtr := flag.String("c", "", "chunked files will be piped to this command")
	startPtr := flag.Int64("b", 0, "start byte of the next block to process")
	flag.Parse()

	fname := *locPtr
	tmploc := *tmpPtr
	cmd := *cmdPtr
	startBlock := *startPtr

	start := time.Now()

	// Ensure that the file name is placed somewhere in the command string.
	//
	// The user has an option to place it anywhere by using %s, otherwise it
	// will be appended to the end of the command string.
	if strings.Contains(cmd, "%s") == false {
		cmd = cmd + " %s"
	}

	pbf, err := streams.Open(fname)
	check(err)
	defer pbf.Close()

	header, err := pbf.ReadFileHeader()

	fmt.Println("File:", pbf.Location)
	fmt.Println("Source:", header.GetSource())
	fmt.Println("OsmosisReplicationBaseUrl:", header.GetOsmosisReplicationBaseUrl())
	fmt.Println("RequiredFeatures:", header.GetRequiredFeatures())
	fmt.Println("Writingprogram:", header.GetWritingprogram())
	fmt.Println("OsmosisReplicationSequenceNumber:", header.GetOsmosisReplicationSequenceNumber())

	headBlock, err := pbf.GetBlock(0)
	check(err)

	headData, err := headBlock.Dump()
	check(err)

	fmt.Printf("Total size: %d bytes\n", pbf.TotalSize)

	var file *os.File

	blocksPerChunk := 5

	c := make(chan int64) // downloaded
	d := make(chan int64) // imported

	downloadedBytes := int64(0)

	if startBlock > 0 {
		downloadedBytes = startBlock
	}

	importedBytes := int64(0)

	var wg sync.WaitGroup

	var downloadSet func(startByte int64)
	var importSet func(cmd string, startByte int64, size int64)

	downloadSet = func(startByte int64) {
		wg.Add(1)
		fname := fmt.Sprintf("%s/%d_chunk_%s", tmploc, startByte, path.Base(pbf.Location))
		file, err = os.Create(fname)
		check(err)
		_, err = file.Write(headData)
		check(err)

		// Push as many Blocks as called for; we use multiple blocks because the
		// osmosis command has a bit of startup and exit overhead.
		p := startByte
		for j := 0; j < blocksPerChunk; j++ {
			if p == pbf.TotalSize {
				break
			}
			block, err := pbf.GetBlock(p)
			check(err)
			_, err = file.Write(headData)
			check(err)
			block.Write(file)
			p = block.BlockEnd
		}
		file.Close()
		downloadedBytes = p
		c <- startByte
		go importSet(cmd, startByte, p - startByte)
		if p < pbf.TotalSize {
			go downloadSet(p)
		} else {
			close(c)
		}
	}

	importSet = func(cmd string, startByte int64, size int64) {
		saveImportState(pbf.Location, startByte)
		fname := fmt.Sprintf("%s/%d_chunk_%s", tmploc, startByte, path.Base(pbf.Location))
		parsed := fmt.Sprintf(cmd, fname)
		args := strings.Split(parsed, " ")
		proc := exec.Command(args[0], args[1:]...)
		out, err := proc.Output()
		if err != nil {
			fmt.Println(string(out))
		}
		check(err)
		os.Remove(fname)
		d <- startByte + size
		wg.Done()
	}

	var progress = func() {
		wg.Add(1)
		for {

			// Output status to the terminal.
			//
			// That \r there is a line return; it means one line will update
			// over and over again instead of having lots of lines printed to
			// the screen.
			fmt.Printf("\r")
			d := humanBytes(downloadedBytes)
			i := humanBytes(importedBytes)
			perc := (float64(importedBytes) / float64(pbf.TotalSize)) * 100
			prog := fmt.Sprintf("%.0f%%", perc)
			status := fmt.Sprintf("Downloaded: %10s Imported: %10s %4.0f", d, i, perc)
			fmt.Printf(status + "%%")

			// Write our status to nginx static files so we can update users
			// playing along from their web browsers.
			//
			// (See ./templates/import.html for the other side of this.)
			f, err := os.Create("/usr/local/data/htdocs/update-status.js")
			check(err)
			f.WriteString("update(")
			f.WriteString(fmt.Sprintf("\"%s\",", d))
			f.WriteString(fmt.Sprintf("\"%s\",", i))
			f.WriteString(fmt.Sprintf("\"%s\",", humanBytes(pbf.TotalSize)))
			f.WriteString(fmt.Sprintf("\"%s\",", time.Since(start)))
			f.WriteString(fmt.Sprintf("\"%s\"", prog))
			f.WriteString(");")
			time.Sleep(time.Second * 1)
			f.Close()

			if perc >= 100 {
				wg.Done()
				break
			}

		}
	}

	if startBlock == 0 {
		startBlock = headBlock.BlockEnd
	}

	go downloadSet(startBlock)
	go progress()
	for p := <-c; p < pbf.TotalSize && p > 0; p = <-c {
		importedBytes = <-d
	}

	wg.Wait()

	fmt.Printf("\nProcessed size: %d bytes\n", pbf.TotalSize)

	fmt.Printf("Processing complete; Total time: %s\n", time.Since(start))

}

func saveImportState(fname string, startByte int64) {
	dir, err := os.Getwd()
	check(err)
	p := path.Join(dir, "save-import-state.sh")
	proc := exec.Command(p, fname, fmt.Sprintf("%d", startByte))
	out, err := proc.Output()
	if err != nil {
		fmt.Println(string(out))
	}
	check(err)
}

func humanBytes(s int64) string {
	units := []string{"B", "KB", "MB", "GB", "TB"}
	n := float64(s)
	i := 0
	for {
		if n < 1024 {
			break
		}
		i++
		n = n / 1024
	}
	return fmt.Sprintf("%0.2f %s", n, units[i])
}