package config

import (
	"os"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var (
	localDBURL string = "root:root123@tcp(127.0.0.1:6603)/bookdb?charset=utf8mb4&parseTime=True&loc=Local"
	db_url     string
)

func GetDB() *gorm.DB {
	db_url = os.Getenv("DBURL")

	if os.Getenv("DBURL") == "" {
		db_url = localDBURL
	}

	db, err := gorm.Open(mysql.Open(db_url), &gorm.Config{})
	if err != nil {
		panic("failed to connect database")
	}
	return db
}
