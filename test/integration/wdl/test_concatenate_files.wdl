version 1.0


import "../../../wdl/subworkflows/concatenate_files.wdl"


workflow test_concatenate_files {
    call concatenate_files.concatenate_files
}
