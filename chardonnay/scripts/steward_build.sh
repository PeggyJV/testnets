set -e

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
