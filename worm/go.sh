pasmo --tapbas -d worm.asm worm.tap worm.map > worm.lis
ret=$?
if [ "$ret" == 0 ]
then
    open worm.tap
else
    echo "assembler problems"
fi
