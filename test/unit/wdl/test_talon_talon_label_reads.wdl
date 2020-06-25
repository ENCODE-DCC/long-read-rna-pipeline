version 1.0


import "../../../wdl/tasks/talon.wdl"


workflow test_talon_talon_label_reads {
    input {
        File input_sam
        File reference_genome
        Resources resources
    }

    call talon.talon_label_reads {
        input:
            input_sam=input_sam,
            reference_genome=reference_genome,
            resources=resources,
    }
}
