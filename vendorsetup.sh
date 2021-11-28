rompath=$(pwd)
vendor_path="vendor/extra"

function apply-waydroid-patches
{
	${vendor_path}/waydroid-patches/apply-patches.sh
}

function waydroid-generate-manifest
{
    ${vendor_path}/manifest_scripts/generate-manifest.sh
}

function update-foss
{
    vendor/foss/update.sh
}

# Save the official lunch command to aosp_lunch() and source it
tmp_lunch="$(mktemp)"
sed '/ lunch()/,/^}/!d'  build/envsetup.sh | sed 's/function lunch/function aosp_lunch/' > "${tmp_lunch}"
source "${tmp_lunch}"
rm -f "${tmp_lunch}"

# Override lunch function to filter lunch targets
function lunch
{
    local T="$(gettop)"
    if [ ! "$T" ]; then
        echo "[lunch] Couldn't locate the top of the tree.  Try setting TOP." >&2
        return 1
    fi

    aosp_lunch $*
	
	if [ -d $T/vendor/foss/ ]; then
		
		
		if [ -f $T/vendor/extra/product.config ]; then
			product=$(cat $T/vendor/extra/product.config)
			echo "product config loaded: ${product}"
		fi
		
		#~ cd $rompath/vendor/foss
		echo "FOSS apps found, determining if update is needed "
		mapfile -t variables < <(grep -oP 'TARGET_ARCH \K[^ ]+' $rompath/out/dumpvars-soong.log)
		for v in "${variables[@]}"; do
			printf "varname=%s\n" "$v"
			wd_arch=$v
			echo -e ${wd_arch} > $T/vendor/extra/product.config
		done
		if [ "$wd_arch" != "$product" ] || [ ! -d $T/vendor/foss/bin/ ]; then
			echo "FOSS apps need to be updated. Doing that now "
			cd $rompath/vendor/foss
			if [ "$wd_arch" = "arm" ]; then
				echo -e "Updating foss apps for ARM"
				. update.sh 4
			fi 
			if [ "$wd_arch" = "arm64" ]; then
				echo -e "Updating foss apps for ARM64"
				. update.sh 2
			fi
			if [ "$wd_arch" = "x86_64" ]; then
				echo -e "Updating foss apps for x86_64"
				. update.sh 1
			fi
			if [ "$wd_arch" = "x86" ]; then
				echo -e "Updating foss apps for x86"
				. update.sh 3
			fi
			cd $rompath
		else
			echo "FOSS apps update not needed "
		fi
	else
		echo "No FOSS vendor found"
	fi
}
