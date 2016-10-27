library('scidb')
scidbconnect()

#Clear old arrays
scidbremove("TEST_VCF_CHROMOSOME", force=TRUE, error=invisible)
scidbremove("TEST_VCF_SAMPLE",     force=TRUE, error=invisible)
scidbremove("TEST_VCF_VARIANT",    force=TRUE, error=invisible)

iquery("create array TEST_VCF_CHROMOSOME <chromosome:string> [chromosome_id=0:24,25,0]")
iquery("create array TEST_VCF_SAMPLE     <sample:string>     [sample_id    =0:* ,50,0 ]")
iquery("create array TEST_VCF_VARIANT    
        <ref:  string,
         alt1: string,
         alt2: string,
         gt1:  uint8,
         gt2:  uint8,
         qual: double,
         info:  string>
        [chromosome_id =0:*,1,0, 
         sample_id     =0:*,50,0,
         pos           =0:*,10000000,0
        ]")

scidbeval(
   as.scidb(c('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','X','Y','MT')),
   name="TEST_VCF_CHROMOSOME",
   gc=0
)
