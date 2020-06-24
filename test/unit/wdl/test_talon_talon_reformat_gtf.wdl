version 1.0


import "../../../wdl/tasks/talon.wdl"


workflow test_talon_talon_reformat_gtf {
    input {
        File input_gtf
        Resources resources
    }

    call talon.talon_reformat_gtf {
        input:
            input_gtf=input_gtf,
            resources=resources,
    }
}
