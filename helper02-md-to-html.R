library(markdown)

# ---
# Convert about.md to html as a fragment
markdownToHTML(file = "./docs/about.md", 
               output = "./docs/about.html", 
               fragment.only = TRUE)
