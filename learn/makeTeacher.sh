#!/bin/sh

cd makeTeacherData

echo $1

ruby parseLogs.rb $1

./a.out result_$1.txt

echo "copy learn.txt and test.txt"

cp ./learn.txt ./../ActionLearning/$1TeacherData/
cp ./test.txt ./../ActionLearning/$1TeacherData/

cd ./../ActionLearning

./a.out $1