#!/bin/sh
# sh 5-nohibernate.sh   (Hibernate Switch 0 = väck ampen och lås hibernate av, state 3)
amixer -c0 cset name="Hibernate Switch" 0
amixer -c0 cset name="R Hibernate Switch" 0
amixer -c0 cget name="Hibernate Switch" | tail -1
amixer -c0 cget name="R Hibernate Switch" | tail -1
