package main

import (
        "fmt"
        "html/template"
        "net/http"
)

func main() {
        // Parse the video.html template once
        tmpl, err := template.ParseFiles("assets/video.html")
        if err != nil {
                fmt.Println("Error parsing template:", err)
                return
        }

        // Register the /video handler
        http.HandleFunc("/video", func(w http.ResponseWriter, r *http.Request) {
                url := r.URL.Query().Get("url")
                if url == "" {
                        http.Error(w, "Missing URL parameter", http.StatusBadRequest)
                        return
                }
                err := tmpl.Execute(w, url)
                if err != nil {
                        http.Error(w, "Template error", http.StatusInternalServerError)
                }
        })

        // Serve static files from the "assets" directory for all other routes
        http.Handle("/", http.FileServer(http.Dir("assets")))

        // Start the server
        fmt.Println("Server started on :8080")
        http.ListenAndServe(":8080", nil)
}