version 1.0


import "../../../wdl/tasks/cat.wdl"


workflow test_cat_cat {
    input {
        Array[File] files
        Resources resources
    }

    call cat.cat {
        input:
            files=files,
            resources=resources,
    }
}
