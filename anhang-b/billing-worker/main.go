// billing-worker – verschickt Rechnungen aus einer Queue (Lab-Demo).
package main

import (
	"fmt"
	"log"
	"os"

	"github.com/google/uuid"
	"github.com/joho/godotenv"
	"github.com/pkg/errors"
)

func main() {
	// .env ist optional; fehlt sie, gelten die Umgebungsvariablen.
	_ = godotenv.Load()
	queue := os.Getenv("BILLING_QUEUE")
	if queue == "" {
		log.Fatal(errors.New("BILLING_QUEUE nicht gesetzt"))
	}
	fmt.Printf("worker %s lauscht auf %s\n", uuid.NewString(), queue)
}
