version 1.0


import "../../../wdl/subworkflows/get_splice_junctions.wdl"


workflow test_get_splice_junctions {
    call get_splice_junctions.get_splice_junctions
}
