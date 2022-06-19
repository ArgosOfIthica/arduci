apt install curl
apt install jq

if [ ! -e arduino-cli ];
    then
        wget https://github.com/arduino/arduino-cli/releases/download/0.23.0/arduino-cli_0.23.0_Linux_64bit.tar.gz && tar -xzf arduino-cli_0.23.0_Linux_64bit.tar.gz
fi

mkdir release
mkdir apps
mkdir out
git submodule update --init --recursive --remote
git submodule update --recursive --remote

get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

export CLI=$(get_abs_filename "./arduino-cli")
export OUT=$(get_abs_filename "./out")
export RELEASE=$(get_abs_filename "./release")
export BOARD='arduino:avr:leonardo'


$CLI core update-index
$CLI core install arduino:avr


game_compile() {
    # $1 : relative game directory
    echo $CLI compile -b $BOARD $1 --output-dir $OUT
}

compile_debug() {
    jq -rc '.[] | select(.target=="target") | .build' data.json | while read i; do
        $(game_compile "$i")
        echo "$i"
    done        
}

compile_permissive() {
    jq -rc '.[] | select(.license=="MIT" or .license=="BSD3" or .license=="Unlicense" or .license=="Apache2") | .build' data.json | while read i; do
        $(game_compile "$i")
    done        
}

compile_gpl3_cart() {
    jq -rc '.[] | select(.license=="GPL3" or .license=="LGPL3") | .build' data.json | while read i; do
        $(game_compile "$i")
    done
    compile_permissive
}

compile_all() {
    jq -rc '.[].build' data.json | while read i; do
        $(game_compile "$i")
    done
}

#libraries
$CLI lib install Arduboy
$CLI lib install Arduboy2
$CLI lib install ArduboyTones
$CLI lib install ArduboyPlaytune
$CLI lib install PGMWrap
$CLI lib install FixedPoints
$CLI lib install Keyboard


compile_all

for file in *.ino.hex; do
    mv $OUT/$file $RELEASE;
done
