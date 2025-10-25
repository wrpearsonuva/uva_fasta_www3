function switch_off(box) {
    box.checked = false;
    return true;
}

function new_seqtype(form, f_value) {

  var pgm_text = form['pgm'].options[form['pgm'].selectedIndex].text;
  var pgm_val = form['pgm'].options[form['pgm'].selectedIndex].value;
  var upper = 6;
  var dmatrix = new Array('+5/-4', 'blastn2', '+4/-4', '+4/-8');
  var pmatrix = new Array('Blosum50 (20%)',
			  'Pam250 (20%)',
			  'VT200 (25%)',
			  'Optima5 (25%)',
			  'BlastP62 (30%)',
			  'VT160 (30%)',
			  'VT120 (35%)',
			  'Blosum80 (40%)',
			  'VT80 (50%)',
			  'VT40 (70%)',
			  'MD40 (70%)',
			  'VT20 (85%)',
			  'MD20 (85%)',
			  'VT10 (90%)',
			  'MD10 (90%)'
			  );
  var blp_matrix = new Array('BLOSUM62', 'PAM30', 'PAM70', 'BLOSUM80', 'BLOSUM45');

  var smatrix = new Array;
  var the_gap = form['gap'];
  var the_ext = form['ext'];
  var dna_off;
  var the_obj; 

  if ((pgm_val == 'fad' || pgm_val == 'rssd'
	|| pgm_val == 'lald' || pgm_val == 'pald' )
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
  else if (pgm_val == 'bp' || pgm_val == 'bx') {
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
    if (pgm_val == 'lal' || pgm_val == 'pal' || pgm_val == 'lnw') {
      the_gap.value = -12;
    }
    else { the_gap.value= -10;}
    the_ext.value= -2;

    if (form['p_lib']) {form['p_lib'].disabled = false;}
    if (form['n_lib']) {form['n_lib'].disabled = true;}
    if (form['ktup']) {set_ktup(form, upper);}

//  alert('Protein/DNA set '+upper);
  }

  var the_matrix = form['smatrix'];
  for (var i=0; i < smatrix.length; i++) {
    the_matrix.options[i]=new Option(smatrix[i],i+dna_off,false);
  }
  the_matrix.options[0].selected=true;
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

  var po_matrix = new Array('-10','-18', '-11','-17','-10','-10','-10','-14','-14','-21','-14','-22','-15','-23','-16');
  var pe_matrix = new Array('-2' ,'-2', '-1', '-3', '-2', '-2', '-2', '-2', '-2', '-4', '-2', '-4', '-2', '-4', '-2');
  var pgm_val = form['pgm'].options[form['pgm'].selectedIndex].value;

  var sel_index = form['smatrix'].selectedIndex;
  var matrix_index = form['smatrix'].options[sel_index].value;

//  alert('sq_type checked: '+form.sq_type[0].checked+'value: '+form.sq_type[0].value+'matrix_index :'+matrix_index);

  if (pgm_val == 'bp' || pgm_val == 'bx') {
    return;
  }

  if (pgm_val == 'fad') {
     form.gap.value = '-12';
     form.ext.value = '-4';
  }
  else {
     form.gap.value = po_matrix[matrix_index];
     form.ext.value = pe_matrix[matrix_index];
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

    if (form['enable_pssm']) {
      form['enable_pssm'].checked = 0;
      document.getElementById('asn_file0').style.display = 'none';
    }

    if (form['p_lib']) {form['p_lib'].disabled = false;}
    if (form['n_lib']) {form['n_lib'].disabled = false;}

    if (form.sq_type[0]) {
	form.sq_type[0].disabled = false;
	form.sq_type[0].checked = true;
	form.sq_type[1].disabled = false;
	form.sq_type[1].checked = false;
	form.sq_type[2].disabled = false;
	form.sq_type[3].disabled = false;
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
	document.getElementById('asn_file0').style.display = 'none';
	form['enable_pssm'].checked = 0;
	form['enable_pssm'].disabled = true;
	document.getElementById('asn_file').style.display = 'none';
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
	pgm_val == 'lal' || pgm_val == 'pal' || 
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
	pgm_val == 'lald' || pgm_val == 'pald'||
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
	pgm_val == 'ff' || pgm_val == 'tf') {
      if (pgm_val == 'fs' || pgm_val == 'ff') {
	 if (form['n_lib']) {form['n_lib'].disabled = true;}
	 form.smatrix.options[6].selected = true;
      }
      else {
	 if (form['p_lib']) {form['p_lib'].disabled = true;}
	 form.smatrix.options[7].selected = true;
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
    }
}

function OnSubmitForm()
{
  var pgm = document.myform['pgm'].options[document.myform['pgm'].selectedIndex].text;

  document.myform.method ="post";

//  if (form['remote'].value==1) { form['rm'].value = 'remote';}

  if (pgm.indexOf("SSEARCH") == 0 ) {
      document.myform.action = ssearch_url ;
  }
  else {
      document.myform.action = search_url;;
  }
  return true;
}

function set_remote(form) {
  form['rm'].value='remote';
  alert("rm is: "+form['rm'].value)

  return true;
}
