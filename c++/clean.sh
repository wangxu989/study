for i in `ls`
do
  if [ -d $i ]
  then
    git rm ./$i/a.out
  fi
done
