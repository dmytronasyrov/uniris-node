#!/usr/bin/env bash

export MIX_ENV=prod

mix distillery.release --env=prod
