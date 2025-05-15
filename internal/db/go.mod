module github.com/locotoki/alfred-agent-platform-v2/internal/db

go 1.21

require (
	github.com/DATA-DOG/go-sqlmock v1.5.0
	github.com/go-sql-driver/mysql v1.7.1
	github.com/lib/pq v1.10.9
	modernc.org/sqlite v1.29.1
)

// Explicitly pin modernc.org/libc to the version required by modernc.org/sqlite
require modernc.org/libc v1.34.11