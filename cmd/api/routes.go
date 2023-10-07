package main

import (
	"net/http"

	"github.com/julienschmidt/httprouter"
)

func (app *application) routes() http.Handler {

	router := httprouter.New()

	router.NotFound = http.HandlerFunc(app.notFoundResponse)
	router.MethodNotAllowed = http.HandlerFunc(app.methodNotAllowedResponse)

	router.HandlerFunc(http.MethodGet, "/v1/healthcheck", app.requireActivatedUSer(app.healthcheckHandler))

	router.HandlerFunc(http.MethodGet, "/v1/movies", app.requirePermission("movies:read", app.requireActivatedUSer(app.listMoviesHandler)))
	router.HandlerFunc(http.MethodPost, "/v1/movies", app.requirePermission("movies:write", app.requireActivatedUSer(app.createMovieHandler)))
	router.HandlerFunc(http.MethodGet, "/v1/movies/:id", app.requirePermission("movies:read", app.requireActivatedUSer(app.showMovieHandler)))
	router.HandlerFunc(http.MethodPatch, "/v1/movies/:id", app.requirePermission("movies:write", app.requireActivatedUSer(app.updateMovieHandler)))
	router.HandlerFunc(http.MethodDelete, "/v1/movies/:id", app.requirePermission("movies:write", app.requireActivatedUSer(app.deleteMovieHandler)))

	router.HandlerFunc(http.MethodPost, "/v1/users", app.registerUserHandler)
	router.HandlerFunc(http.MethodPut, "/v1/users/activated", app.activateUserHandler)

	router.HandlerFunc(http.MethodPost, "/v1/tokens/authentication", app.createAuthTokenHandler)

	return app.recoverPanic(app.enabledCORS(app.rateLimit(app.authenticate(router))))
}
