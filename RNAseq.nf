#! /usr/bin/env nextflow
// Copyright (C) 2017 IARC/WHO

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

params.input_folder = null
params.input_file   = null
params.ref_folder   = null
params.gtf          = null
params.bed          = null

params.cpu          = 4
params.mem          = 50
params.mem_QC       = 2
params.fastq_ext    = "fq.gz"
params.suffix1      = "_1"
params.suffix2      = "_2"
params.output_folder= "."
params.ref          = "ref.fa"
params.GATK_jar     = "GenomeAnalysisTK.jar"
params.GATK_bundle  = "GATK_bundle"
params.RG           = "PL:ILLUMINA"
params.stranded     = "no"
params.hisat2_idx   = "genome_tran"
params.cpu_trim     = 15
params.multiqc_config = null
params.sjtrim       = null
params.recalibration= null
params.hisat2       = null

params.cutadapt     = null

params.htseq_maxreads= null //default value of htseq-count is 30000000
params.help         = null


log.info "" 
log.info "--------------------------------------------------------"
log.info "  RNAseq-nf 1.0.0: alignment, QC, and reads counting workflow for RNA sequencing "
log.info "--------------------------------------------------------"
log.info "Copyright (C) IARC/WHO"
log.info "This program comes with ABSOLUTELY NO WARRANTY; for details see LICENSE"
log.info "This is free software, and you are welcome to redistribute it"
log.info "under certain conditions; see LICENSE for details."
log.info "--------------------------------------------------------"
log.info ""


if (params.help) {
    log.info '-------------------------------------------------------------'
    log.info ' USAGE  '
    log.info '-------------------------------------------------------------'
    log.info ''
    log.info 'nextflow run iarcbioinfo/RNAseq.nf [-with-docker] --input_folder input/ --ref_folder ref/ [OPTIONS]'
    log.info ''
    log.info 'Mandatory arguments:'
    log.info '    --input_folder   FOLDER                  Folder containing BAM or fastq files to be aligned.'
    log.info '--input_file     STRING              Input file (comma-separated) with 3 columns:'
    log.info '    --ref_folder          FOLDER                   Folder with genome reference files (with index).'
    log.info '    --gtf          FILE                    Annotation file.'
    log.info '    --bed        STRING                bed file with interval list'
    log.info ""
    log.info 'Optional arguments:'
    log.info '    --ref          FILE                    Reference fasta file (with index) for splice junction trimming and base recalibration.'
    log.info '    --output_folder     STRING                Output folder (default: results_alignment).'
    log.info '    --cpu          INTEGER                 Number of cpu used by bwa mem and sambamba (default: 8).'
    log.info '    --mem          INTEGER                 Size of memory used for mapping (in GB) (default: 32).'
    log.info '    --mem_QC     INTEGER                 Size of memory used for QC and cutadapt (in GB) (default: 32).'
    log.info '    --RG           STRING                  Samtools read group specification (default : PL:ILLUMINA).'
    log.info '    --fastq_ext        STRING                Extension of fastq files (default : fq.gz)'
    log.info '    --suffix1        STRING                Suffix of fastq files 1 (default : _1)'
    log.info '    --suffix2        STRING                Suffix of fastq files 2 (default : _2)'
    log.info '    --GATK_bundle        STRING                path to GATK bundle files (default : .)'
    log.info '    --GATK_jar        STRING                path to GATK GenomeAnalysisTK.jar file (default : .)'
    log.info '    --stranded        STRING                are reads stranded? (default : no; alternatives : yes, r)'
    log.info '    --hisat2_idx        STRING                hisat2 index file prefix (default : genome_tran)'
    log.info ''
    log.info 'Flags:'
    log.info '    --sjtrim                    enable splice junction trimming'
    log.info '    --recalibration                    performs base quality score recalibration (GATK)'
    log.info '    --hisat2                    use hisat2 instead of STAR for reads mapping'
    log.info '    --cutadapt                  perform adapter sequence trimming'
    log.info ''
    exit 0



params.sjtrim       = null
params.recalibration = null
params.hisat2       = null

params.htseq_maxreads = null //default value of htseq-count is 30000000
params.help         = null

}else {
  /* Software information */
  log.info "input_folder = ${params.input_folder}"
  log.info "input_file   = ${params.input_file}"
  log.info "ref          = ${params.ref}"
  log.info "cpu          = ${params.cpu}"
  log.info "mem          = ${params.mem}"
  log.info "fastq_ext    = ${params.fastq_ext}"
  log.info "suffix1      = ${params.suffix1}"
  log.info "suffix2      = ${params.suffix2}"
  log.info "output_folder= ${params.output_folder}"
  log.info "bed          = ${params.bed}"
  log.info "GATK_bundle  = ${params.GATK_bundle}"
  log.info "GATK_jar     = ${params.GATK_jar}"
  log.info "mem_QC       = ${params.mem_QC}"
  log.info "ref_folder   = ${params.ref_folder}"
  log.info "gtf          = ${params.gtf}"
  log.info "RG           = ${params.RG}"
  log.info "stranded     = ${params.stranded}"
  log.info "hisat2_idx   = ${params.hisat2_idx}"
  log.info "sjtrim       = ${params.sjtrim}"
  log.info "hisat2       = ${params.hisat2}"
  log.info "htseq_maxreads=${params.htseq_maxreads}"
  log.info "recalibration= ${params.recalibration}"

  log.info "help=${params.help}"
}

//multiqc config file
if(params.multiqc_config){
	ch_config_for_multiqc = file(params.multiqc_config)
}else{
	ch_config_for_multiqc = 'NO_FILE'
}

//read ref files
if(params.hisat2){
	ref_1  = Channel.fromPath(params.ref_folder + '/' + params.hisat2_idx + '.1.ht2')
	ref_2  = Channel.fromPath(params.ref_folder + '/' + params.hisat2_idx + '.2.ht2')
	ref_3  = Channel.fromPath(params.ref_folder + '/' + params.hisat2_idx + '.3.ht2')
	ref_4  = Channel.fromPath(params.ref_folder + '/' + params.hisat2_idx + '.4.ht2')
	ref_5  = Channel.fromPath(params.ref_folder + '/' + params.hisat2_idx + '.5.ht2')
	ref_6  = Channel.fromPath(params.ref_folder + '/' + params.hisat2_idx + '.6.ht2')
	ref_7  = Channel.fromPath(params.ref_folder + '/' + params.hisat2_idx + '.7.ht2')
	ref_8  = Channel.fromPath(params.ref_folder + '/' + params.hisat2_idx + '.8.ht2')
	ref    = ref_1.concat( ref_2,ref_3,ref_4,ref_5,ref_6,ref_7,ref_8)
}else{
	ref_1  = Channel.fromPath(params.ref_folder +'/chrStart.txt')
	ref_2  = Channel.fromPath(params.ref_folder +'/chrNameLength.txt')
	ref_3  = Channel.fromPath(params.ref_folder +'/chrName.txt')
	ref_4  = Channel.fromPath(params.ref_folder +'/chrLength.txt')
	ref_5  = Channel.fromPath(params.ref_folder +'/exonGeTrInfo.tab')
	ref_6  = Channel.fromPath(params.ref_folder +'/exonInfo.tab')
	ref_7  = Channel.fromPath(params.ref_folder +'/geneInfo.tab')
	ref_8  = Channel.fromPath(params.ref_folder +'/Genome')
	ref_9  = Channel.fromPath(params.ref_folder +'/genomeParameters.txt')
	ref_10 = Channel.fromPath(params.ref_folder +'/SA')
	ref_11 = Channel.fromPath(params.ref_folder +'/SAindex')
	ref_12 = Channel.fromPath(params.ref_folder +'/sjdbInfo.txt')
	ref_13 = Channel.fromPath(params.ref_folder +'/transcriptInfo.tab')
	ref_14 = Channel.fromPath(params.ref_folder +'/sjdbList.fromGTF.out.tab')
	ref_15 = Channel.fromPath(params.ref_folder +'/sjdbList.out.tab')
	ref    = ref_1.concat( ref_2,ref_3,ref_4,ref_5,ref_6,ref_7,ref_8,ref_9,ref_10,ref_11,ref_12,ref_13,ref_14,ref_15)
	//ref.into { ref_align; ref_fusion }
}


gtf    = file(params.gtf)
bed    = file(params.bed)

//read files
if(params.input_file){
	mode = 'infile'
	Channel.fromPath("${params.input_file}")
     	       .splitCsv( header: true, sep: '\t', strip: true )
	       .map { row -> [ row.SM , row.RG , file(row.pair1), file(row.pair2) ] }
	       .into{ readPairs ; readPairs2}
	//readPairs2merge = readPairstmp.groupTuple(by: 0)
    	//            		      .map { row -> tuple(row[0] , row[1] , row[1][0], row[2][0], row[3][0])  }
	//single   = Channel.create()
	//multiple = Channel.create()
	//multiple1 = Channel.create()
	//multiple2 = Channel.create()
	//readPairs2merge.choice( single,multiple ) { a -> a[1].size() == 1 ? 0 : 1 }
	//single2 = single.map { row -> tuple(row[0] , 1 , row[1][0], row[2][0], row[3][0])  }
	//multiple.separate(multiple1,multiple2){ row -> [ [row[0] , row[1].size() ,  row[1][0], row[2][0], row[3][0]] , [row[0] , 2 , row[1][1], row[2][1],  row[3][1]] ] }
	//readPairs=single2.concat(multiple1 ,multiple2 )*/
}else{
	mode = 'fastq'
	if (file(params.input_folder).listFiles().findAll { it.name ==~ /.*${params.fastq_ext}/ }.size() > 0){
	    println "fastq files found, proceed with alignment"
	}else{
	    if (file(params.input_folder).listFiles().findAll { it.name ==~ /.*bam/ }.size() > 0){
	        println "BAM files found, proceed with realignment"; mode ='bam'
		files = Channel.fromPath( params.input_folder+'/*.bam' )
		               .map {  path -> [ path.name.replace(".bam",""), path.name.replace(".bam","") ,  path ] }
	    }else{
	        println "ERROR: input folder contains no fastq nor BAM files"; System.exit(0)
	    }
	}
}

if(mode=='bam'){
    process bam2fastq {
        cpus '1'
        memory params.mem_QC+'G'
        tag { file_tag }
        
        input:
        set val(file_tag) , val(rg), file(infile) from files
     
        output:
	set val(file_tag), val(file_tag), file("${file_tag}_1.fq.gz"), file("${file_tag}_2.fq.gz")  into readPairs0

        shell:
	file_tag = infile.baseName
		
        '''
        set -o pipefail
        samtools collate -uOn 128 !{file_tag}.bam tmp_!{file_tag} | samtools fastq -1 !{file_tag}_1.fq -2 !{file_tag}_2.fq -
	gzip !{file_tag}_1.fq
	gzip !{file_tag}_2.fq
        '''
    }
    readPairs0.into{ readPairs ; readPairs2}
}else{
if(mode=='fastq'){
    println "fastq mode"
    
    keys1 = file(params.input_folder).listFiles().findAll { it.name ==~ /.*${params.suffix1}.${params.fastq_ext}/ }.collect { it.getName() }
                                                                                                               .collect { it.replace("${params.suffix1}.${params.fastq_ext}",'') }
    keys2 = file(params.input_folder).listFiles().findAll { it.name ==~ /.*${params.suffix2}.${params.fastq_ext}/ }.collect { it.getName() }
                                                                                                               .collect { it.replace("${params.suffix2}.${params.fastq_ext}",'') }
    if ( !(keys1.containsAll(keys2)) || !(keys2.containsAll(keys1)) ) {println "\n ERROR : There is not at least one fastq without its mate, please check your fastq files."; System.exit(0)}

// Gather files ending with _1 suffix
   reads1 = Channel
    .fromPath( params.input_folder+'/*'+params.suffix1+'.'+params.fastq_ext )
    .map {  path -> [ path.name.replace("${params.suffix1}.${params.fastq_ext}",""), path ] }

// Gather files ending with _2 suffix
   reads2 = Channel
    .fromPath( params.input_folder+'/*'+params.suffix2+'.'+params.fastq_ext )
    .map {  path -> [ path.name.replace("${params.suffix2}.${params.fastq_ext}",""), path ] }

// Match the pairs on two channels having the same 'key' (name) and emit a new pair containing the expected files
   reads1
    .phase(reads2)
    .map { pair1, pair2 -> [ pair1[0] , pair1[0] , pair1[1], pair2[1] ] }
    .into{ readPairs ; readPairs2}

    //println reads1
}
}



// pre-trimming QC
process fastqc_pretrim {
	cpus params.cpu
        memory params.mem_QC+'GB'    
        tag { file_tag }
        
        input:
        set val(file_tag), val(rg), file(pair1) , file(pair2) from readPairs
	
        output:
	file("*_pretrim_fastqc.zip") into fastqc_pairs
	
	publishDir "${params.output_folder}/QC/fastq", mode: 'copy', pattern: '{*fastqc.zip}'

	shell:
	basename1=pair1.baseName.split("\\.")[0]
	basename2=pair2.baseName.split("\\.")[0]
        '''
	fastqc -t !{task.cpus} !{pair1} !{pair2}
	mv !{basename1}_fastqc.zip !{basename1}_pretrim_fastqc.zip
	mv !{basename2}_fastqc.zip !{basename2}_pretrim_fastqc.zip 
        '''
}

// adapter sequence trimming and post trimming QC
if(params.cutadapt!=null){
	process adapter_trimming {
            cpus params.cpu_trim
            memory params.mem_QC+'GB'
            tag { file_tag }
	    
            input:
	    set val(file_tag), val(rg), file(pair1), file(pair2) from readPairs2
	    
            output:
            set val(file_tag), val(rg) , file("${file_tag}*val_1.fq.gz"), file("${file_tag}*val_2.fq.gz")  into readPairs3
	    file("*_val_*_fastqc.zip") into fastqc_postpairs
	    file("*trimming_report.txt") into trimming_reports
	    
	    publishDir "${params.output_folder}/QC/adapter_trimming", mode: 'copy', pattern: '{*report.txt,*fastqc.zip}'
	    
            shell:
	    cpu_tg = params.cpu_trim -1 
	    println cpu_tg
	    cpu_tg2 = cpu_tg.div(3.5)
	    //println cpu_tg2
	    cpu_tg3 = Math.round(Math.ceil(cpu_tg2))
	    println cpu_tg3
            '''
	    trim_galore --paired --fastqc --basename !{file_tag}_!{rg} -j !{cpu_tg3} !{pair1} !{pair2}
            '''
	}
}else{
	readPairs3 = readPairs2
	fastqc_postpairs=null
	trimming_reports=null
}

readPairs_align = Channel.create()
readPairs_align2print = Channel.create()
readPairs_aligntmp = readPairs3.groupTuple(by: 0)
			       .into(readPairs_align,readPairs_align2print)

readPairs_align2print.subscribe { row -> println "${row}" }

//                            .map { row -> tuple(row[0] , row[1], row[2] , row[3][0] , row[4][0]  ) }

//Mapping, mark duplicates and sorting
process alignment {
      cpus params.cpu
      memory params.mem+'G'
      tag { file_tag }
      
      input:
      set val(file_tag), val(rg),  file(pair1), file(pair2)  from readPairs_align
      file ref from ref.collect()
      file gtf
                  
      output:
      set val(file_tag), val(rg) , file("${file_tag}.bam"), file("${file_tag}.bam.bai") into bam_files
      file("*Log*") into align_out
      set val(file_tag), file("*SJ.out.junction") into SJ_out
      file("*SJ.out.tab") into SJ_out_others
      if( (params.sjtrim == null)&&(params.recalibration == null) ){
      	publishDir params.output_folder, mode: 'copy', saveAs: {filename ->
                 if (filename.indexOf(".bam") > 0)                      "BAM/$filename"
            else if (filename.indexOf("SJ") > 0)              "BAM/$filename"
            else if (filename.indexOf("Log") > 0)             "QC/alignment/$filename"
        }
      }else{
	publishDir params.output_folder, mode: 'copy', saveAs: {filename ->
            if (filename.indexOf("SJ") > 0)              "BAM/$filename"
            else if (filename.indexOf("Log") > 0)             "QC/alignment/$filename"
        }
      }
            
      shell:
      println !{rg}
      println !{pair1}
      align_threads = params.cpu.intdiv(2)
      sort_threads = params.cpu.intdiv(2) - 1
      sort_mem     = params.mem.intdiv(4)
      input_f1="${pair1[0]}"
      input_f2="${pair2[0]}"
      rgline="ID:${file_tag}_${rg[0]} SM:${file_tag} ${params.RG}"
      for( p1tmp in pair1.drop(1) ){
	input_f1=input_f1+",${p1tmp}"
      }
      for( p2tmp in pair2.drop(1) ){
        input_f2=input_f2+",${p2tmp}"
      }
      for( rgtmp in rg.drop(1) ){
        rgline=rgline+" , ID:${file_tag}_${rgtmp} SM:${file_tag} ${params.RG}"
      }
      '''
      STAR --outSAMattrRGline !{rgline} --chimSegmentMin 12 --chimJunctionOverhangMin 12 --chimSegmentReadGapMax 3 --alignSJDBoverhangMin 10 --alignMatesGapMax 100000 --alignIntronMax 100000 --alignSJstitchMismatchNmax 5 -1 5 5 --outSAMstrandField intronMotif --chimMultimapScoreRange 10 --chimMultimapNmax 10 --chimNonchimScoreDropMin 10 --peOverlapNbasesMin 12 --peOverlapMMp 0.1 --chimOutJunctionFormat 1 --twopassMode Basic --outReadsUnmapped None --runThreadN !{align_threads} --genomeDir . --sjdbGTFfile !{gtf} --readFilesCommand zcat --readFilesIn !{input_f1} !{input_f2} --outStd SAM | samblaster --addMateTags | sambamba view -S -f bam -l 0 /dev/stdin | sambamba sort -t !{sort_threads} -m !{sort_mem}G --tmpdir=!{file_tag}_tmp -o !{file_tag}.bam /dev/stdin
      mv Chimeric.out.junction STAR.!{file_tag}.Chimeric.SJ.out.junction
      mv SJ.out.tab STAR.!{file_tag}.SJ.out.tab
      mv Log.final.out STAR.!{file_tag}.Log.final.out
      mv Log.out STAR.!{file_tag}.Log.out
      mv Log.progress.out    STAR.!{file_tag}.Log.progress.out
      mv Log.std.out STAR.!{file_tag}.Log.std.out
      '''
}

fasta_ref       = file(params.ref)
fasta_ref_fai   = file(params.ref + '.fai')


if( (params.sjtrim!=null)||(params.recalibration!=null) ){
    fasta_ref_dictn = params.ref[0..<params.ref.lastIndexOf('.')]
    fasta_ref_dict  = file(fasta_ref_dictn  + '.dict')
}

//Splice junctions trimming
if(params.sjtrim){
   GATK_jar=file(params.GATK_jar)
   
   process splice_junct_trim {
      cpus params.cpu
      memory params.mem+'G'
      tag { file_tag }
      
      input:
      set val(file_tag), val(rg), file(bam), file(bai)  from bam_files
      file fasta_ref
      file fasta_ref_fai
      file fasta_ref_dict     
      file GATK_jar
            
      output:
      set val(file_tag_new), val(rg), file("${file_tag_new}.bam"), file("${file_tag_new}.bam.bai") into bam_files2
      if(params.recalibration == null){
        publishDir "${params.output_folder}/BAM", mode: 'copy'
      }
            
      shell:
      file_tag_new = file_tag+'_split'
      '''
      java -Xmx!{params.mem}g -Djava.io.tmpdir=. -jar !{GATK_jar} -T SplitNCigarReads -R !{fasta_ref} -I !{bam} -o !{file_tag_new}.bam -rf ReassignOneMappingQuality -RMQF 255 -RMQT 60 -U ALLOW_N_CIGAR_READS
      mv !{file_tag_new}.bai !{file_tag_new}.bam.bai
      '''
   }
}else{
      bam_files2=bam_files
}


//BQSrecalibration GATK<4
if(params.recalibration){
   GATK_jar     = file(params.GATK_jar)
   bundle_indel = Channel.fromPath(params.GATK_bundle + '/*indels*.vcf')
   bundle_dbsnp = Channel.fromPath(params.GATK_bundle + '/*dbsnp*.vcf')

   process base_quality_score_recalibration {
    	cpus params.cpu
	memory params.mem+'G'
    	tag { file_tag }
        
    	input:
	set val(file_tag), val(rg) , file(bam), file(bai) from bam_files2
	file fasta_ref
      	file fasta_ref_fai
	file fasta_ref_dict
      	file bed
	file GATK_jar
    	file indel from bundle_indel.collect()
	file dbsnp from bundle_dbsnp.collect()
	
    	output:
	set val(file_tag_new), val(rg), file("${file_tag_new}.bam"), file("${file_tag_new}.bam.bai") into recal_bam_files
    	file("${file_tag}_recal.table") into recal_table_files
    	file("${file_tag}_post_recal.table") into recal_table_post_files
    	file("${file_tag}_recalibration_plots.pdf") into recal_plots_files
    	publishDir params.output_folder, mode: 'copy', saveAs: {filename ->
                 if (filename.indexOf(".bam") > 0)                      "BAM/$filename"
            else "QC/BQSR/$filename"
        }

    	shell:
	file_tag_new = file_tag+'_recal'
    	'''
    	indelsvcf=(`ls *indels*.vcf`)
    	dbsnpvcfs=(`ls *dbsnp*.vcf`)
    	dbsnpvcf=${dbsnpvcfs[@]:(-1)}
    	knownSitescom=''
    	for ll in $indelsvcf; do knownSitescom=$knownSitescom' -knownSites:VCF '$ll; done
    	knownSitescom=$knownSitescom' -knownSites:VCF '$dbsnpvcf
    	java -Xmx!{params.mem}g -Djava.io.tmpdir=. -jar !{GATK_jar} -T BaseRecalibrator -filterRNC -nct !{params.cpu} -R !{fasta_ref} -I !{file_tag}.bam $knownSitescom -L !{bed} -o !{file_tag}_recal.table
    	java -Xmx!{params.mem}g -Djava.io.tmpdir=. -jar !{GATK_jar} -T BaseRecalibrator -filterRNC -nct !{params.cpu} -R !{fasta_ref} -I !{file_tag}.bam $knownSitescom -BQSR !{file_tag}_recal.table -L !{bed} -o !{file_tag}_post_recal.table		
    	java -Xmx!{params.mem}g -Djava.io.tmpdir=. -jar !{GATK_jar} -T AnalyzeCovariates -R !{fasta_ref} -before !{file_tag}_recal.table -after !{file_tag}_post_recal.table -plots !{file_tag}_recalibration_plots.pdf	
    	java -Xmx!{params.mem}g -Djava.io.tmpdir=. -jar !{GATK_jar} -T PrintReads -filterRNC -nct !{params.cpu} -R !{fasta_ref} -I !{file_tag}.bam -BQSR !{file_tag_new}.table -L !{bed} -o !{file_tag_new}.bam
    	mv !{file_tag_new}.bai !{file_tag_new}.bam.bai
    	'''
   }
}else{      
      recal_bam_files=bam_files2
}

recal_bam_files.into { recal_bam_files4QC; recal_bam_files4quant ; recal_bam4QCsplittmp }

//RSEQC
process RSEQC{
    		cpus '1'
		memory params.mem_QC+'GB'
    		tag { file_tag }
        
		input:
    		set val(file_tag), val(rg), file(bam), file(bai) from recal_bam_files4QC
		file bed
		
    		output:
		file("${file_tag}_readdist.txt") into rseqc_files
		file("*clipping*") into rseqc_clip_files
		file("*jun_saturation*") into rseqc_jsat_files
    		publishDir "${params.output_folder}/QC/bam", mode: 'copy'

    		shell:
    		'''
		read_distribution.py -i !{bam} -r !{bed} > !{file_tag}"_readdist.txt"
		clipping_profile.py  -i !{bam} -s "PE" -o !{file_tag}"_clipping"
		junction_saturation.py -i !{bam} -r !{bed} -o !{file_tag}"_jun_saturation"
    		'''
}


simple = Channel.create()
recal_bam_files4QCsplit0 = Channel.create()
recal_bam_files4QCsplit = Channel.create()
recal_bam_files4QCsplit4test = Channel.create()
recal_bam4QCsplittmp.choice( simple,recal_bam_files4QCsplit0 ) { a -> a[1].size() == 1 ? 0 : 1 }
recal_bam_files4QCsplit0.into( recal_bam_files4QCsplit , recal_bam_files4QCsplit4test)

process RSEQCsplit{
                cpus '1'
                memory params.mem_QC+'GB'
                tag { file_tag }

                input:
                set val(file_tag), val(rg), file(bam), file(bai) from recal_bam_files4QCsplit
                file bed

                output:
                file("*readdist.txt") into rseqc_files_split
                publishDir "${params.output_folder}/QC/bam", mode: 'copy'

                shell:
		basename = bam.baseName
                '''
                samtools split !{bam} -f "%*_%!.%."
		for f in `ls !{basename}_*.bam`;
		do read_distribution.py -i $f -r !{bed} > ${f%.bam}"_readdist.txt";
		done
		'''
}

if( recal_bam_files4QCsplit4test.ifEmpty(0)==0 ){
	recal_bam_files4QCsplit4test.subscribe { row -> println "${row}" }
	println("No files to split")
	rseqc_files_split = ['NO_FILE']
}

//Quantification
process quantification{
    	if( (params.sjtrim)||(params.recalibration) ){
		cpus params.cpu
		memory params.mem+'GB'
	}else{
		cpus '1'
		memory params.mem_QC+'GB'
	}
	
    	tag { file_tag }
        
    	input:
    	set val(file_tag), val(rg), file(bam), file(bai) from recal_bam_files4quant
	file gtf

    	output:
	file("${file_tag}_count.txt") into htseq_files
    	publishDir "${params.output_folder}/counts", mode: 'copy'

    	shell:
	buffer=''
	if(params.htseq_maxreads) buffer='--max-reads-in-buffer '+params.htseq_maxreads
	
	if( (params.sjtrim)||(params.recalibration) ){
	'''
	htseq-count -h
	mv !{file_tag}.bam !{file_tag}_coordinate_sorted.bam
	sambamba sort -n -t !{task.cpus} -m !{params.mem}G --tmpdir=!{file_tag}_tmp -o !{file_tag}.bam !{file_tag}_coordinate_sorted.bam
	htseq-count -r name -s !{params.stranded} -f bam !{file_tag}.bam !{gtf} !{buffer} --additional-attr=gene_name > !{file_tag}_count.txt 
	'''
	}else{
	 	'''
		htseq-count -r pos -s !{params.stranded} -f bam !{file_tag}.bam !{gtf} !{buffer} --additional-attr=gene_name > !{file_tag}_count.txt 
    		'''
	}
}


process multiqc_pretrim {
    cpus '1'
    memory params.mem_QC+'GB'
    tag { "all"}
        
    input:
    file fastqc1 from fastqc_pairs.collect()
    file multiqc_config from ch_config_for_multiqc    
    
    output:
    file("multiqc_pretrim_report.html") into multiqc_pre
    file("multiqc_pretrim_report_data") into multiqc_pre_data
    publishDir "${params.output_folder}/QC", mode: 'copy'

    shell:
    if( multiqc_config=='NO_FILE' ){
        opt = ""
    }else{
        opt = '--config'+ multiqc_config
    }
    '''
    for f in $(find *fastqc.zip -type l);do cp --remove-destination $(readlink $f) $f;done;
    multiqc . -n multiqc_pretrim_report.html -m fastqc !{opt} --comment "RNA-seq Pre-trimming QC report"
    '''
}


process multiqc_posttrim {
    cpus '1'
    memory params.mem_QC+'GB'
    tag { "all"}
        
    input:
    file STAR from align_out.collect()
    file htseq from htseq_files.collect()
    file rseqc_clip from rseqc_clip_files.collect()
    file rseqc from rseqc_files.collect()
    file rseqc_jsat from rseqc_jsat_files.collect()
    file trim from trimming_reports.collect()
    file fastqcpost from fastqc_postpairs.collect()
    file rseqc_split from rseqc_files_split.collect().ifEmpty([])
    file multiqc_config from ch_config_for_multiqc
        
    output:
    file("multiqc_posttrim_report.html") into multiqc_post
    file("multiqc_posttrim_report_data") into multiqc_post_data

    publishDir "${params.output_folder}/QC", mode: 'copy'

    shell:
    if( multiqc_config=='NO_FILE' ){
	opt = ""
    }else{
	opt = '--config'+ multiqc_config
    }
    '''
    for f in $(find *fastqc.zip -type l);do cp --remove-destination $(readlink $f) $f;done;
    multiqc . -n multiqc_posttrim_report.html -m fastqc -m cutadapt -m star -m rseqc -m htseq !{opt} --comment "RNA-seq Post-trimming QC report"
    '''
}
