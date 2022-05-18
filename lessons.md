# Lessons

Things learned from working on this project.

## `io.popen` just doesn't seem to work at all under Redbean on Windows

I've tried running scripts and nothing happens. I tried adding the scripts to the directories that lua is allowed to access from redbean, but that does nothing. I've tried using a very simple command and still got no output. I tried intentionally passing a bad command, and I get no indication that anything failed. I have no idea whether `io.popen` works at all in this scenario.

Instead, I'm going to resort to generating the index manually and reading it on startup. I was hoping I could do something more elegant than that, but it doesn't seem like it's in the cards.