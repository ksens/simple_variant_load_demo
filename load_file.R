library('scidb')
scidbconnect()
CHROMOSOME = scidb("TEST_VCF_CHROMOSOME")
SAMPLE     = scidb("TEST_VCF_SAMPLE")
VARIANT    = scidb("TEST_VCF_VARIANT")

create_schema = function()
{
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
  
  
}

load_file = function(file_path)
{
  file_path='/home/scidb/load/test_file_1'
  input = scidb(sprintf("aio_input('%s', 'num_attributes=8')", file_path))
  input = scidbeval(input, temp=TRUE)
  if(count(input)==0)
  {
    stop("No rows ingested")
  }
  if(count(subset(input, "error is not null")) !=0)
  {
    stop("Received error rows")
  }
  sample_name = (project(subset(input, tuple_no==0 && dst_instance_id==0 && src_instance_id==0), "a7")[])$a7
  print(sprintf("Loading sample %s", sample_name))
  if(count(subset(SAMPLE, sample==sprintf('%s',sample_name))) != 0)
  {
    stop("Sample already exists in the database")
  }
  load_sample_query = transform(as.scidb(sample_name), sample=val)
  load_sample_query = merge(load_sample_query, 
                            aggregate(transform(SAMPLE, sample_id=sample_id), 
                                      FUN="max(sample_id) as max_sample_id"))
  load_sample_query = transform(load_sample_query, sample_id = "iif(max_sample_id is null, 0, max_sample_id+1)")
  iquery(sprintf("insert(redimension(%s, %s), %s)", load_sample_query@name, SAMPLE@name, SAMPLE@name))
  
  load_query = transform(input, sample=sprintf("'%s'",sample_name))
  load_query = subset(load_query, tuple_no>0 || dst_instance_id!=0)
  load_query = index_lookup(load_query, SAMPLE, attr="sample", new_attr="sample_id")
  load_query = index_lookup(load_query, CHROMOSOME, attr="a0", new_attr="chromosome_id")
  load_query = transform(load_query,
                         pos="int64(a1)",
                         ref="a2",
                         alt1="nth_csv(a3,0)",
                         alt2="nth_csv(a3,1)",
                         qual = "dcast(a4, double(null))",
                         info="a5",
                         gt1="dcast(nth_tdv(a7,0,'|'), uint8(null))",
                         gt2="dcast(nth_tdv(a7,1,'|'), uint8(null))"
                    )
  iquery(sprintf("insert(redimension(%s, %s), %s)", load_query@name, VARIANT@name, VARIANT@name))
}