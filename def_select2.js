var dmatrix = new Array (
    {id:21, name:'+5/-4', gop:-10, gext: -2},
    {id:22, name:'blastn2', gop:-10, gext: -2},
    {id:23, name:'+4/-4', gop:-10, gext: -2},
    {id:24, name:'+4/-8', gop:-10, gext: -2}
 );

var pmatrix = new Array (
    {id:0, name:'Blosum50 (25%)', gop:-10, gext: -2},
    {id:4, name:'BlastP62 (30%)', gop: -11, gext: -1},
    {id:1, name:'Pam250 (20%)', gop:-10, gext: -2},
    {id:2, name:'VT200 (25%)', gop: -10, gext: -2},
    {id:3, name:'Optima5 (25%)', gop: -18, gext: -2},
    {id:5, name:'VT160 (30%)', gop: -12, gext: -2},
    {id:6, name:'VT120 (35%)', gop: -11, gext: -1},
    {id:7, name:'Blosum80 (40%)', gop: -10, gext: -1},
    {id:8, name:'VT80 (50%)', gop: -11, gext: -1},
    {id:9, name:'VT40 (70%)', gop: -13, gext: -1},
    {id:11, name:'VT20 (85%)', gop: -15, gext: -2},
    {id:13, name:'VT10 (90%)', gop: -16, gext: -2}
);

var fp_matrix = new Array (
    {id:12, name:'MD20-MS (85%)', gop: -15, gext: -2},
    {id:14, name:'MD10-MS (92%)', gop: -16, gext: -2}
);

var blp_matrix = new Array (
    {id:1, name:'BLOSUM62', gop: 11, gext: 1},
    {id:2, name:'BLOSUM80', gop: 11, gext: 1},
    {id:3, name:'PAM70', gop: 11, gext: 1},
    {id:4, name:'PAM30', gop: 10, gext: 1},
    {id:5, name:'BLOSUM45', gop: 10, gext: 2}
);

var annot_types = new Array
  (
   {},
   {id:'ann2_null', descr:"No annotation"},
   {id:'ann2_ipr_up', descr:"InterPro Domains/Uniprot features"},
   {id:'ann2_up_up', descr:"UniprotDomains/Uniprot features"},
   {id:'ann2_ipr', descr:"InterPro Domains/no features"},
   {id:'ann2_pfam', descr:"Pfam annotations"},
   {id:'ann2_pfam_acc', descr:"Pfam annotations (PF00XXX)"},
   {id:'ann2_cath', descr:"CATH structural domains"},
   {id:'ann2_cath_ipr', descr:"CATH classes (10.20.30.40)"},
   {id:'ann2_RPD2_acc', descr:"RPD2 annotations (PF00XXX)"}
);

function switch_off(box) {
    box.checked = false;
    return true;
}

function can_annot(form) {
  var f_value_f = form['p_lib'];

  if (f_value_f === undefined) {return;}

  var f_value = f_value_f.options[form['p_lib'].selectedIndex].value;
  f_value = f_value.toUpperCase()

  if (f_value == 'B') {
    document.getElementById('annot2_div').style.display='inline';
    document.getElementById('ann2_RPD2_acc').selected=true;
  }
  else if (f_value == 'C' || f_value=='Q' || f_value=='S' || f_value=='P') {
    document.getElementById('annot2_div').style.display='inline';
    annot_sel = annot_types[5].id;
    document.getElementById('ann2_pfam').selected=true;
  }
  else if (f_value == 'D') {
    document.getElementById('annot2_div').style.display='inline';
    document.getElementById('ann2_cath').selected=true;
  }
  // do this for everything now using seqdb_demo2 join
  else if (f_value == 'S') {
    document.getElementById('annot2_div').style.display='none';
  }
  else {
    if (document.getElementById('annot2_div')) {
	document.getElementById('annot2_div').style.display='inline';
	document.getElementById(annot2_def).selected=true;
      }
  }
  //
  //  else {
  //    document.getElementById('annot2_div').style.display='none';
  //  }

  // deal with annot_seq1
  var annot1_def_f = form['annot_seq1'];
  if (document.getElementById(annot1_def_f)) {
     document.getElementById(annot1_def_f).selected=true;
  }
}

function update_annot1_def(form) {
  var annot1_def_f = form['annot_seq1'];
  annot1_def = annot1_def_f.options[annot1_def_f.selectedIndex];
}

function new_seqtype(form, f_value) {

  var pgm_text = form['pgm'].options[form['pgm'].selectedIndex].text;
  var pgm_val = form['pgm'].options[form['pgm'].selectedIndex].value;
  var upper = 6;

  var smatrix = new Array;
  var the_gap = form['gap'];
  var the_ext = form['ext'];
  var dna_off;
  var the_obj;

  if (document.getElementById('annot2_div')) {
    document.getElementById('annot2_div').style.display='none';
    form['annot_seq2'].checked=0;
  }

  if ((pgm_val == 'fad' || pgm_val == 'rssd'
       || pgm_val == 'lald'
       || pgm_val == 'lpald' || pgm_val == 'pald' )
      && f_value >= 2 && f_value <= 4) {

    // DNA
    upper = 6;
    smatrix = dmatrix;
    dna_off = 20;
    the_gap.value= -12;
    the_ext.value= -4;

    //    alert('Protein/DNA set '+upper);

    if (form['p_lib']) {form['p_lib'].disabled = true;}
    if (form['n_lib']) {form['n_lib'].disabled = false;}
    if (form['ktup']) {set_ktup(form, upper);}
  }
  else if (pgm_val == 'bp' || pgm_val == 'bx' || pgm_val == 'pbp') {
    // blast
    if (form['p_lib']) {form['p_lib'].disabled = false;}
    if (form['n_lib']) {form['n_lib'].disabled = true;}
    smatrix = blp_matrix;
    dna_off = 0;
    the_gap.value= 11;
    the_ext.value= 1;
  }
  else {
    // Protein
    upper = 2;
    smatrix = pmatrix;
    dna_off = 0;
    if (pgm_val == 'lal' || pgm_val == 'pal' || pgm_val == 'lpal' || pgm_val == 'lnw') {
      the_gap.value = -12;
    }
    else { the_gap.value = -10;}
    the_ext.value= -2;

    if (form['p_lib']) {
      form['p_lib'].disabled = false;
      can_annot(form);
    }
    if (form['n_lib']) {form['n_lib'].disabled = true;}
    if (form['ktup']) {set_ktup(form, upper);}

//  alert('Protein/DNA set '+upper);
  }

  update_matrix_menu(form, smatrix, 0);
}

function update_matrix_menu(form, smatrix, default_val) {

  var the_matrix = form['smatrix'];
  for (var i=0; i < smatrix.length; i++) {
    the_matrix.options[i]=new Option(smatrix[i].name,smatrix[i].id,false);
  }
  the_matrix.options[default_val].selected=true;
  the_matrix.options.length=smatrix.length;
}

function set_ktup(form, upper) {
  var the_ktup = form.ktup;

//  alert('upper is ' + upper + ' value is: ' + f_value);

    the_ktup.options[0]=new Option(' ktup ?? ',0,false);

    var j = upper;
    for (var i=0; i <upper;  i++, j--) {
      the_ktup.options[i]=new Option('ktup = '+j,j);
    }
    the_ktup.options[0].selected=true;
    the_ktup.options.selectedIndex=0;
    the_ktup.options.length=upper;

//   alert('upper is ' + upper + ' value is: ' + f_value);

}

function update_gap(form) {

//    var po_matrix = new Array('-10','-7','-11','-17','-10','-16','-21','-24','-23','-18');
//    var pe_matrix = new Array('-2' ,'-1', '-1', '-3', '-2', '-4', '-4', '-4','-4','-2');
  var pgm_val = form['pgm'].options[form['pgm'].selectedIndex].value;

  var sel_index = form['smatrix'].selectedIndex;
  var matrix_index = form['smatrix'].options[sel_index].value;
  var smatrix = pmatrix;

//  alert('sq_type checked: '+form.sq_type[0].checked+'value: '+form.sq_type[0].value+'matrix_index :'+matrix_index);

  if (pgm_val == 'bp' || pgm_val == 'bx' || pgm_val == 'pbp') {
    form.gap.value = blp_matrix[sel_index].gop;
    form.ext.value = blp_matrix[sel_index].gext;
    return;
  }

  //  var last = pgm_val.lastIndexOf('d');
  //  var len = pgm_val.length;

  if (pgm_val[pgm_val.length-1]=='d') {
     form.gap.value = '-12';
     form.ext.value = '-4';
  }
  else {
     form.gap.value = smatrix[sel_index].gop;
     form.ext.value = smatrix[sel_index].gext;
  }
}

// this program should update the sq_type options given the program

function update_pgm(form) {

    var pgm_text = form['pgm'].options[form['pgm'].selectedIndex].text;
    var pgm_val = form['pgm'].options[form['pgm'].selectedIndex].value;
    var run_mode = form['rm'].value;


//    if (!form.pgm[0].checked) {
//	form.sq_type[0].checked=true;
//	form.sq_type[0].selectedIndex=0;
//	new_seqtype(form,1);
//    }

    can_annot(form);

    if (form['enable_pssm']) {
      form['enable_pssm'].checked = 0;
      document.getElementById('asn_file0').style.display = 'none';
    }

    if (form['p_lib']) {form['p_lib'].disabled = false;}
    if (form['n_lib']) {form['n_lib'].disabled = false;}

    if (form.sq_type[0]) {
	// enable all sequence types
	form.sq_type[0].disabled = form.sq_type[1].disabled = form.sq_type[2].disabled = form.sq_type[3].disabled = false;

	form.sq_type[0].checked = true;
	form.sq_type[1].checked = false;
    }

    if (form['msa_asn_file']) {
      if (pgm_val == 'sw' || pgm_val == 'rss' || pgm_val == 'gnw' || pgm_val == 'lnw') {
	document.getElementById('asn_file0').style.display = 'block';
	form['enable_pssm'].disabled = false;
	if (form['enable_pssm'].checked == 1) {
	  document.getElementById('asn_file').style.display = 'block';
	}
	else {
	  document.getElementById('asn_file').style.display = 'none';
	}
	form['msa_asn_file'].disabled = false;
      }
      else {
	if (document.getElementById('asn_file0')) {
	  document.getElementById('asn_file0').style.display = 'none';
	}
	if (form['enable_pssm']) {
	  form['enable_pssm'].checked = 0;
	  form['enable_pssm'].disabled = true;
	}
	if (document.getElementById('asn_file')) {
	  document.getElementById('asn_file').style.display = 'none';
	}
	form['msa_asn_file'].disabled = true;
      }
    }

    if (form['pdfdev']) {
      // the run_mode set is the future run mode, not the current one
      if (run_mode == 'lalign_r' && (pgm_val == 'pal' || pgm_val == 'pald')) {
	document.getElementById('pdfdiv').style.display = 'block';
	form['pdfdev'].disabled = false;
      }
      else {
	document.getElementById('pdfdiv').style.display = 'none';
	form['pdfdev'].disabled = true;
      }
    }

    if (pgm_val == 'fap' || pgm_val == 'rss' ||
	pgm_val == 'lal' || pgm_val == 'pal' || pgm_val == 'lpal' ||
	pgm_val == 'sw' ||
	pgm_val == 'gnw' || pgm_val == 'lnw' ||
	pgm_val == 'bp' ) {
      if (form['n_lib']) {form['n_lib'].disabled = true;}
      if (form.sq_type[0]) {
	form.sq_type[1].disabled = true;
	form.sq_type[2].disabled = true;
	form.sq_type[3].disabled = true;
      }
      if (form['segflag']) {
	form.segflag.checked = true;
	form.segflag.disabled = false;
      }
      new_seqtype(form,1);
    }

    if (pgm_val == 'fad' || pgm_val == 'rssd' ||
	pgm_val == 'lald' || pgm_val == 'pald'|| pgm_val == 'lpald'||
	pgm_val == 'bn' || pgm_val == 'bx') {
      if (form['p_lib']) {form['p_lib'].disabled = true;}
      if (form.sq_type[0]) {
	form.sq_type[0].disabled = true;
	form.sq_type[1].checked = true;
      }
      new_seqtype(form,2);
      if (form['segflag']) {
	form.segflag.checked = false;
	form.segflag.disabled = true;
      }
    }

    if (pgm_val == 'pal' || pgm_val == 'pald') {
      document.getElementById('pdfdiv').style.display = 'block';
      form.pdfdev.disabled = false;
    }

    if (pgm_val == 'fs' || pgm_val == 'tfs' ||
	pgm_val == 'ff' || pgm_val == 'tfx') {
      if (pgm_val == 'fs' || pgm_val == 'ff') {
	 if (form['n_lib']) {form['n_lib'].disabled = true;}

	 update_matrix_menu(form, fp_matrix, 12);
	 //	 form.smatrix.options[6].selected = true;
      }
      else {
	 if (form['p_lib']) {form['p_lib'].disabled = true;}
	 update_matrix_menu(form, fp_matrix, 14);
	 //	 form.smatrix.options[7].selected = true;
      }
      if (form.sq_type[0]) {
	  form.sq_type[0].checked = true;
	  form.sq_type[1].disabled = true;
	  form.sq_type[2].disabled = true;
	  form.sq_type[3].disabled = true;
      }
      if (form[ext]) {
	  form.ext.disabled = true;
	  form.gap.disabled = true;
	  update_gap(form);
      }
      if (form['ktup']) {form.ktup.options[1].selected = true;}
      if (form['segflag']) {
	form.segflag.checked = false;
      }
    }

    if (pgm_text.indexOf('SSEARCH')==0 ||
	pgm_text.indexOf('PRSS')==0 ||
	pgm_val == 'gnw' || pgm_val == 'lnw'  ||
	pgm_val == 'bp' || pgm_val == 'bx' ) {

      if (form['ktup']) {form['ktup'].disabled = true;}
    }
    else {
      if (form['ktup']) {form['ktup'].disabled = false;}
    }

    if (pgm_text.indexOf('SSEARCH') == 0 || pgm_text.indexOf('FASTF')==0 ||
	pgm_val == 'gnw' || pgm_val == 'lnw' ) {
      if (form['n_lib']) {form['n_lib'].disabled = true;}
      if (form.sq_type[0]) {
	  form.sq_type[1].disabled = true;
	  form.sq_type[2].disabled = true;
	  form.sq_type[3].disabled = true;
      }
    }
    if (pgm_val == 'fx' || pgm_val == 'fy' ||
	pgm_val == 'rfx' || pgm_val == 'bx') {
      if (form['n_lib']) {form['n_lib'].disabled = true;}
      if (form.sq_type[0]) {
	  form.sq_type[1].checked = true;
	  form.sq_type[0].checked = false;
	  form.sq_type[0].disabled = true;
	  new_seqtype(form,1);
      }

      if (form['segflag']) {
	form.segflag.checked = true;
	form.segflag.disabled = false;
      }
    }

    if (pgm_text.indexOf('TFAST') == 0 ) {
      if (form['p_lib']) {form['p_lib'].disabled = true;}
      if (form['n_lib']) {form['n_lib'].disabled = false;}
      if (form.sq_type[0]) {form.sq_type[1].disabled = true;}
      update_matrix_menu(form, pmatrix, 1);
    }

    can_annot(form);
}

function OnSubmitForm() {
//    var pgm = document.myform['pgm'].options[document.myform['pgm'].selectedIndex].text;

    document.myform.method ="post";

    //  if (form['remote'].value==1) { form['rm'].value = 'remote';}

    document.myform.action = search_url;;
    return true;
}

function set_remote(form) {
  form['rm'].value='remote';
  alert("rm is: "+form['rm'].value)

  return true;
}
