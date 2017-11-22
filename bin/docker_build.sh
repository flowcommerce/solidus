set -x

rake assets:clean
rake assets:precompile

rm public/.sprockets-manifest*
cp public/assets/.sprockets-manifest* public/

# docker build flowdocker/solidus:0.2.0 .
