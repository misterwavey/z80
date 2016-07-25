APP=comp8
pasmo --tapbas -d $APP.asm $APP.tap $APP.map > $APP.lis
ret=$?
if [ "$ret" == 0 ]
then
    open $APP.tap
else
    echo "assembler problems"
fi
