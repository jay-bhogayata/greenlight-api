package data

import (
	"database/sql"
	"errors"
)

var (
	ErrRecordNotFound = errors.New("record not found")
	ErrEditConflict   = errors.New("edit conflict")
)

type Models struct {
	Movies     MovieModel
	Permission PermissionModel
	Token      TokenModel
	Users      UserModel
}

func NewModels(db *sql.DB) Models {
	return Models{
		Movies:     MovieModel{DB: db},
		Permission: PermissionModel{DB: db},
		Token:      TokenModel{DB: db},
		Users:      UserModel{DB: db},
	}
}
