APP=comp8
pasmo --tapbas -d $APP.asm $APP.tap $APP.map > $APP.lis
ret=$?
if [ "$ret" == 0 ]
then
    #wine "/Users/stuart/.wine/drive_c/Program Files/ZXSpin_07s/ZXSpin.exe" "Z:\Users\stuart\dev\z80\src\z80\comp8\comp8.tap"
    open $APP.tap
else
    echo "assembler problems"
fi
