# Julia Heroku Endpoint demo

This is a very simple example of a Julia-powered API that you can run locally or deploy to the [Heroku](http://heroku.com) hosting platform.  

Note: Heroku can use buildpacks but here we're using their Docker container hosting service.  Either would work for this simple example, but once you start including lots of packages the best way to make sure it will work once deployed is to use the container.

The `server.jl` file includes everything you need to deploy a simple API.  The included one has two endpoints:

`/echo` accepts a [base-64](https://en.wikipedia.org/wiki/Base64) encoded JSON and returns it with a slight modification.

`/loglog` accepts a floating point number (let's call it `x`) and returns `log(log(x))`.  

There's also a default endpoint at `/` and any other routes will return a "Not found" error.  

## Running the server locally through native Julia

First, start the server on port 5000 by running `julia server.jl 5000` in this package folder.  The server is now running!  

You can test the first endpoint by navigating to [http://localhost/echo/eyJNZXNzYWdlIjoiSGVsbG8hIn0=].  That funky-looking string is just the encoding for `{Message: "Hello!"}`.  If you don't believe me, you can use [this free Javascript REPL](https://repl.it/languages/javascript) to run the following and check the output.  

```javascript
var obj = {Message: "Hello!"}
console.log(btoa(JSON.stringify(obj)))
```

You can test the second endpoint by going to [http://localhost/loglog/1234.234] or similar.  

## Running the server locally from inside Docker

Before we can share this wonderful server with the world, we first need to wrap it up nicely in a Docker container that we can then deploy to Heroku.  First, install [Docker](https://www.docker.com/) if you don't have it already.  Make sure the basic examples run for you.  

Next, run `docker build -t sample-endpoints .` in this project folder. This may take a bit the first time you run it, but when it's done you now have a container called `sample-endpoints`.  You can run this locally with:

```
docker run -i -t --rm -p 5000:5000 -e PORT=5000 sample-endpoints
```

You can read about this plethora of options [here](https://docs.docker.com/engine/reference/run/) but basically it runs the server with the environment variable `PORT` set to 5000, and lets external connections on port 5000 into the container on the same port.  You can then connect to it using the same endpoints, but you will need to go to `http://192.168.99.100` rather than `localhost`.  This IP could be different depending on your Docker configuration.  

Sometimes you may want to start up the image so you can connect to it rather than running the server immediately for debug.  You can do this with:

```
docker run -dit -p 5000:5000 --entrypoint=/bin/bash sample-endpoints
```

## Deploying to Heroku

Now comes the time to share your exciting endpoints with the world!  First, install the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli), the install the container-registry plugin and log in as discussed [here](https://devcenter.heroku.com/articles/container-registry-and-runtime).

Once you've done that, you can create a Heroku app using something like:

```
heroku create sample-endpoints
```

but you will need to replace `sample-endpoints` with your own unique name.  You can push it to Heroku with:

```
heroku container:push web -app sample-endpoints
```

and then turn it on by scaling it to a single web dyno:

```
heroku ps:scale web=1
```

You should then be able to go to [https://sample-endpoints.herokuapp.com/loglog/12345] or similar to see it in action!  
