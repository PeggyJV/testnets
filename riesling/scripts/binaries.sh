set -e

# Sommelier
cd ~
mkdir sommelier_8.0.0_linux_amd64
cd sommelier_8.0.0_linux_amd64
wget https://github.com/PeggyJV/sommelier/releases/download/v8.0.0/sommelier_8.0.0_linux_amd64.tar.gz
tar -xvf sommelier_8.0.0_linux_amd64.tar.gz
sudo cp sommelier /usr/bin/sommelier
cd ~

# Steward
work_dir=$(pwd)/temp
out_dir=$(pwd)/bin
mkdir -p $work_dir
chmod -R 777 $work_dir
mkdir -p $out_dir
cd $work_dir
git clone https://github.com/peggyjv/steward
cd steward
cargo build --bin steward --release
cp $work_dir/steward/target/release/steward $outdir/steward
cd $(pwd)
rm -r $work_dir
cd ~
