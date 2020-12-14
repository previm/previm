var zip_WSIZE = 32768;
var zip_STORED_BLOCK = 0;
var zip_STATIC_TREES = 1;
var zip_DYN_TREES = 2;
var zip_DEFAULT_LEVEL = 6;
var zip_FULL_SEARCH = true;
var zip_INBUFSIZ = 32768;
var zip_INBUF_EXTRA = 64;
var zip_OUTBUFSIZ = 1024 * 8;
var zip_window_size = 2 * zip_WSIZE;
var zip_MIN_MATCH = 3;
var zip_MAX_MATCH = 258;
var zip_BITS = 16;
var zip_LIT_BUFSIZE = 8192;
var zip_HASH_BITS = 13;
if (zip_LIT_BUFSIZE > zip_INBUFSIZ) {
  alert("error: zip_INBUFSIZ is too small")
}
if ((zip_WSIZE << 1) > (1 << zip_BITS)) {
  alert("error: zip_WSIZE is too large")
}
if (zip_HASH_BITS > zip_BITS - 1) {
  alert("error: zip_HASH_BITS is too large")
}
if (zip_HASH_BITS < 8 || zip_MAX_MATCH != 258) {
  alert("error: Code too clever")
}
var zip_DIST_BUFSIZE = zip_LIT_BUFSIZE;
var zip_HASH_SIZE = 1 << zip_HASH_BITS;
var zip_HASH_MASK = zip_HASH_SIZE - 1;
var zip_WMASK = zip_WSIZE - 1;
var zip_NIL = 0;
var zip_TOO_FAR = 4096;
var zip_MIN_LOOKAHEAD = zip_MAX_MATCH + zip_MIN_MATCH + 1;
var zip_MAX_DIST = zip_WSIZE - zip_MIN_LOOKAHEAD;
var zip_SMALLEST = 1;
var zip_MAX_BITS = 15;
var zip_MAX_BL_BITS = 7;
var zip_LENGTH_CODES = 29;
var zip_LITERALS = 256;
var zip_END_BLOCK = 256;
var zip_L_CODES = zip_LITERALS + 1 + zip_LENGTH_CODES;
var zip_D_CODES = 30;
var zip_BL_CODES = 19;
var zip_REP_3_6 = 16;
var zip_REPZ_3_10 = 17;
var zip_REPZ_11_138 = 18;
var zip_HEAP_SIZE = 2 * zip_L_CODES + 1;
var zip_H_SHIFT = parseInt((zip_HASH_BITS + zip_MIN_MATCH - 1) / zip_MIN_MATCH);
var zip_free_queue;
var zip_qhead, zip_qtail;
var zip_initflag;
var zip_outbuf = null;
var zip_outcnt, zip_outoff;
var zip_complete;
var zip_window;
var zip_d_buf;
var zip_l_buf;
var zip_prev;
var zip_bi_buf;
var zip_bi_valid;
var zip_block_start;
var zip_ins_h;
var zip_hash_head;
var zip_prev_match;
var zip_match_available;
var zip_match_length;
var zip_prev_length;
var zip_strstart;
var zip_match_start;
var zip_eofile;
var zip_lookahead;
var zip_max_chain_length;
var zip_max_lazy_match;
var zip_compr_level;
var zip_good_match;
var zip_nice_match;
var zip_dyn_ltree;
var zip_dyn_dtree;
var zip_static_ltree;
var zip_static_dtree;
var zip_bl_tree;
var zip_l_desc;
var zip_d_desc;
var zip_bl_desc;
var zip_bl_count;
var zip_heap;
var zip_heap_len;
var zip_heap_max;
var zip_depth;
var zip_length_code;
var zip_dist_code;
var zip_base_length;
var zip_base_dist;
var zip_flag_buf;
var zip_last_lit;
var zip_last_dist;
var zip_last_flags;
var zip_flags;
var zip_flag_bit;
var zip_opt_len;
var zip_static_len;
var zip_deflate_data;
var zip_deflate_pos;
var zip_extra_lbits = new Array(0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0);
var zip_extra_dbits = new Array(0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13);
var zip_extra_blbits = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 7);
var zip_bl_order = new Array(16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);
var zip_configuration_table = new Array(new zip_DeflateConfiguration(0, 0, 0, 0), new zip_DeflateConfiguration(4, 4, 8, 4), new zip_DeflateConfiguration(4, 5, 16, 8), new zip_DeflateConfiguration(4, 6, 32, 32), new zip_DeflateConfiguration(4, 4, 16, 16), new zip_DeflateConfiguration(8, 16, 32, 32), new zip_DeflateConfiguration(8, 16, 128, 128), new zip_DeflateConfiguration(8, 32, 128, 256), new zip_DeflateConfiguration(32, 128, 258, 1024), new zip_DeflateConfiguration(32, 258, 258, 4096));

function zip_DeflateCT() {
  this.fc = 0;
  this.dl = 0
}

function zip_DeflateTreeDesc() {
  this.dyn_tree = null;
  this.static_tree = null;
  this.extra_bits = null;
  this.extra_base = 0;
  this.elems = 0;
  this.max_length = 0;
  this.max_code = 0
}

function zip_DeflateConfiguration(f, e, h, g) {
  this.good_length = f;
  this.max_lazy = e;
  this.nice_length = h;
  this.max_chain = g
}

function zip_DeflateBuffer() {
  this.next = null;
  this.len = 0;
  this.ptr = new Array(zip_OUTBUFSIZ);
  this.off = 0
}

function zip_deflate_start(b) {
  var a;
  if (!b) {
    b = zip_DEFAULT_LEVEL
  } else {
    if (b < 1) {
      b = 1
    } else {
      if (b > 9) {
        b = 9
      }
    }
  }
  zip_compr_level = b;
  zip_initflag = false;
  zip_eofile = false;
  if (zip_outbuf != null) {
    return
  }
  zip_free_queue = zip_qhead = zip_qtail = null;
  zip_outbuf = new Array(zip_OUTBUFSIZ);
  zip_window = new Array(zip_window_size);
  zip_d_buf = new Array(zip_DIST_BUFSIZE);
  zip_l_buf = new Array(zip_INBUFSIZ + zip_INBUF_EXTRA);
  zip_prev = new Array(1 << zip_BITS);
  zip_dyn_ltree = new Array(zip_HEAP_SIZE);
  for (a = 0; a < zip_HEAP_SIZE; a++) {
    zip_dyn_ltree[a] = new zip_DeflateCT()
  }
  zip_dyn_dtree = new Array(2 * zip_D_CODES + 1);
  for (a = 0; a < 2 * zip_D_CODES + 1; a++) {
    zip_dyn_dtree[a] = new zip_DeflateCT()
  }
  zip_static_ltree = new Array(zip_L_CODES + 2);
  for (a = 0; a < zip_L_CODES + 2; a++) {
    zip_static_ltree[a] = new zip_DeflateCT()
  }
  zip_static_dtree = new Array(zip_D_CODES);
  for (a = 0; a < zip_D_CODES; a++) {
    zip_static_dtree[a] = new zip_DeflateCT()
  }
  zip_bl_tree = new Array(2 * zip_BL_CODES + 1);
  for (a = 0; a < 2 * zip_BL_CODES + 1; a++) {
    zip_bl_tree[a] = new zip_DeflateCT()
  }
  zip_l_desc = new zip_DeflateTreeDesc();
  zip_d_desc = new zip_DeflateTreeDesc();
  zip_bl_desc = new zip_DeflateTreeDesc();
  zip_bl_count = new Array(zip_MAX_BITS + 1);
  zip_heap = new Array(2 * zip_L_CODES + 1);
  zip_depth = new Array(2 * zip_L_CODES + 1);
  zip_length_code = new Array(zip_MAX_MATCH - zip_MIN_MATCH + 1);
  zip_dist_code = new Array(512);
  zip_base_length = new Array(zip_LENGTH_CODES);
  zip_base_dist = new Array(zip_D_CODES);
  zip_flag_buf = new Array(parseInt(zip_LIT_BUFSIZE / 8))
}

function zip_deflate_end() {
  zip_free_queue = zip_qhead = zip_qtail = null;
  zip_outbuf = null;
  zip_window = null;
  zip_d_buf = null;
  zip_l_buf = null;
  zip_prev = null;
  zip_dyn_ltree = null;
  zip_dyn_dtree = null;
  zip_static_ltree = null;
  zip_static_dtree = null;
  zip_bl_tree = null;
  zip_l_desc = null;
  zip_d_desc = null;
  zip_bl_desc = null;
  zip_bl_count = null;
  zip_heap = null;
  zip_depth = null;
  zip_length_code = null;
  zip_dist_code = null;
  zip_base_length = null;
  zip_base_dist = null;
  zip_flag_buf = null
}

function zip_reuse_queue(a) {
  a.next = zip_free_queue;
  zip_free_queue = a
}

function zip_new_queue() {
  var a;
  if (zip_free_queue != null) {
    a = zip_free_queue;
    zip_free_queue = zip_free_queue.next
  } else {
    a = new zip_DeflateBuffer()
  }
  a.next = null;
  a.len = a.off = 0;
  return a
}

function zip_head1(a) {
  return zip_prev[zip_WSIZE + a]
}

function zip_head2(a, b) {
  return zip_prev[zip_WSIZE + a] = b
}

function zip_put_byte(a) {
  zip_outbuf[zip_outoff + zip_outcnt++] = a;
  if (zip_outoff + zip_outcnt == zip_OUTBUFSIZ) {
    zip_qoutbuf()
  }
}

function zip_put_short(a) {
  a &= 65535;
  if (zip_outoff + zip_outcnt < zip_OUTBUFSIZ - 2) {
    zip_outbuf[zip_outoff + zip_outcnt++] = (a & 255);
    zip_outbuf[zip_outoff + zip_outcnt++] = (a >>> 8)
  } else {
    zip_put_byte(a & 255);
    zip_put_byte(a >>> 8)
  }
}

function zip_INSERT_STRING() {
  zip_ins_h = ((zip_ins_h << zip_H_SHIFT) ^ (zip_window[zip_strstart + zip_MIN_MATCH - 1] & 255)) & zip_HASH_MASK;
  zip_hash_head = zip_head1(zip_ins_h);
  zip_prev[zip_strstart & zip_WMASK] = zip_hash_head;
  zip_head2(zip_ins_h, zip_strstart)
}

function zip_SEND_CODE(b, a) {
  zip_send_bits(a[b].fc, a[b].dl)
}

function zip_D_CODE(a) {
  return (a < 256 ? zip_dist_code[a] : zip_dist_code[256 + (a >> 7)]) & 255
}

function zip_SMALLER(b, c, a) {
  return b[c].fc < b[a].fc || (b[c].fc == b[a].fc && zip_depth[c] <= zip_depth[a])
}

function zip_read_buff(d, b, c) {
  var a;
  for (a = 0; a < c && zip_deflate_pos < zip_deflate_data.length; a++) {
    d[b + a] = zip_deflate_data.charCodeAt(zip_deflate_pos++) & 255
  }
  return a
}

function zip_lm_init() {
  var a;
  for (a = 0; a < zip_HASH_SIZE; a++) {
    zip_prev[zip_WSIZE + a] = 0
  }
  zip_max_lazy_match = zip_configuration_table[zip_compr_level].max_lazy;
  zip_good_match = zip_configuration_table[zip_compr_level].good_length;
  if (!zip_FULL_SEARCH) {
    zip_nice_match = zip_configuration_table[zip_compr_level].nice_length
  }
  zip_max_chain_length = zip_configuration_table[zip_compr_level].max_chain;
  zip_strstart = 0;
  zip_block_start = 0;
  zip_lookahead = zip_read_buff(zip_window, 0, 2 * zip_WSIZE);
  if (zip_lookahead <= 0) {
    zip_eofile = true;
    zip_lookahead = 0;
    return
  }
  zip_eofile = false;
  while (zip_lookahead < zip_MIN_LOOKAHEAD && !zip_eofile) {
    zip_fill_window()
  }
  zip_ins_h = 0;
  for (a = 0; a < zip_MIN_MATCH - 1; a++) {
    zip_ins_h = ((zip_ins_h << zip_H_SHIFT) ^ (zip_window[a] & 255)) & zip_HASH_MASK
  }
}

function zip_longest_match(f) {
  var h = zip_max_chain_length;
  var c = zip_strstart;
  var d;
  var g;
  var b = zip_prev_length;
  var e = (zip_strstart > zip_MAX_DIST ? zip_strstart - zip_MAX_DIST : zip_NIL);
  var a = zip_strstart + zip_MAX_MATCH;
  var j = zip_window[c + b - 1];
  var i = zip_window[c + b];
  if (zip_prev_length >= zip_good_match) {
    h >>= 2
  }
  do {
    d = f;
    if (zip_window[d + b] != i || zip_window[d + b - 1] != j || zip_window[d] != zip_window[c] || zip_window[++d] != zip_window[c + 1]) {
      continue
    }
    c += 2;
    d++;
    do {} while (zip_window[++c] == zip_window[++d] && zip_window[++c] == zip_window[++d] && zip_window[++c] == zip_window[++d] && zip_window[++c] == zip_window[++d] && zip_window[++c] == zip_window[++d] && zip_window[++c] == zip_window[++d] && zip_window[++c] == zip_window[++d] && zip_window[++c] == zip_window[++d] && c < a);
    g = zip_MAX_MATCH - (a - c);
    c = a - zip_MAX_MATCH;
    if (g > b) {
      zip_match_start = f;
      b = g;
      if (zip_FULL_SEARCH) {
        if (g >= zip_MAX_MATCH) {
          break
        }
      } else {
        if (g >= zip_nice_match) {
          break
        }
      }
      j = zip_window[c + b - 1];
      i = zip_window[c + b]
    }
  } while ((f = zip_prev[f & zip_WMASK]) > e && --h != 0);
  return b
}

function zip_fill_window() {
  var c, a;
  var b = zip_window_size - zip_lookahead - zip_strstart;
  if (b == -1) {
    b--
  } else {
    if (zip_strstart >= zip_WSIZE + zip_MAX_DIST) {
      for (c = 0; c < zip_WSIZE; c++) {
        zip_window[c] = zip_window[c + zip_WSIZE]
      }
      zip_match_start -= zip_WSIZE;
      zip_strstart -= zip_WSIZE;
      zip_block_start -= zip_WSIZE;
      for (c = 0; c < zip_HASH_SIZE; c++) {
        a = zip_head1(c);
        zip_head2(c, a >= zip_WSIZE ? a - zip_WSIZE : zip_NIL)
      }
      for (c = 0; c < zip_WSIZE; c++) {
        a = zip_prev[c];
        zip_prev[c] = (a >= zip_WSIZE ? a - zip_WSIZE : zip_NIL)
      }
      b += zip_WSIZE
    }
  } if (!zip_eofile) {
    c = zip_read_buff(zip_window, zip_strstart + zip_lookahead, b);
    if (c <= 0) {
      zip_eofile = true
    } else {
      zip_lookahead += c
    }
  }
}

function zip_deflate_fast() {
  while (zip_lookahead != 0 && zip_qhead == null) {
    var a;
    zip_INSERT_STRING();
    if (zip_hash_head != zip_NIL && zip_strstart - zip_hash_head <= zip_MAX_DIST) {
      zip_match_length = zip_longest_match(zip_hash_head);
      if (zip_match_length > zip_lookahead) {
        zip_match_length = zip_lookahead
      }
    }
    if (zip_match_length >= zip_MIN_MATCH) {
      a = zip_ct_tally(zip_strstart - zip_match_start, zip_match_length - zip_MIN_MATCH);
      zip_lookahead -= zip_match_length;
      if (zip_match_length <= zip_max_lazy_match) {
        zip_match_length--;
        do {
          zip_strstart++;
          zip_INSERT_STRING()
        } while (--zip_match_length != 0);
        zip_strstart++
      } else {
        zip_strstart += zip_match_length;
        zip_match_length = 0;
        zip_ins_h = zip_window[zip_strstart] & 255;
        zip_ins_h = ((zip_ins_h << zip_H_SHIFT) ^ (zip_window[zip_strstart + 1] & 255)) & zip_HASH_MASK
      }
    } else {
      a = zip_ct_tally(0, zip_window[zip_strstart] & 255);
      zip_lookahead--;
      zip_strstart++
    } if (a) {
      zip_flush_block(0);
      zip_block_start = zip_strstart
    }
    while (zip_lookahead < zip_MIN_LOOKAHEAD && !zip_eofile) {
      zip_fill_window()
    }
  }
}

function zip_deflate_better() {
  while (zip_lookahead != 0 && zip_qhead == null) {
    zip_INSERT_STRING();
    zip_prev_length = zip_match_length;
    zip_prev_match = zip_match_start;
    zip_match_length = zip_MIN_MATCH - 1;
    if (zip_hash_head != zip_NIL && zip_prev_length < zip_max_lazy_match && zip_strstart - zip_hash_head <= zip_MAX_DIST) {
      zip_match_length = zip_longest_match(zip_hash_head);
      if (zip_match_length > zip_lookahead) {
        zip_match_length = zip_lookahead
      }
      if (zip_match_length == zip_MIN_MATCH && zip_strstart - zip_match_start > zip_TOO_FAR) {
        zip_match_length--
      }
    }
    if (zip_prev_length >= zip_MIN_MATCH && zip_match_length <= zip_prev_length) {
      var a;
      a = zip_ct_tally(zip_strstart - 1 - zip_prev_match, zip_prev_length - zip_MIN_MATCH);
      zip_lookahead -= zip_prev_length - 1;
      zip_prev_length -= 2;
      do {
        zip_strstart++;
        zip_INSERT_STRING()
      } while (--zip_prev_length != 0);
      zip_match_available = 0;
      zip_match_length = zip_MIN_MATCH - 1;
      zip_strstart++;
      if (a) {
        zip_flush_block(0);
        zip_block_start = zip_strstart
      }
    } else {
      if (zip_match_available != 0) {
        if (zip_ct_tally(0, zip_window[zip_strstart - 1] & 255)) {
          zip_flush_block(0);
          zip_block_start = zip_strstart
        }
        zip_strstart++;
        zip_lookahead--
      } else {
        zip_match_available = 1;
        zip_strstart++;
        zip_lookahead--
      }
    }
    while (zip_lookahead < zip_MIN_LOOKAHEAD && !zip_eofile) {
      zip_fill_window()
    }
  }
}

function zip_init_deflate() {
  if (zip_eofile) {
    return
  }
  zip_bi_buf = 0;
  zip_bi_valid = 0;
  zip_ct_init();
  zip_lm_init();
  zip_qhead = null;
  zip_outcnt = 0;
  zip_outoff = 0;
  if (zip_compr_level <= 3) {
    zip_prev_length = zip_MIN_MATCH - 1;
    zip_match_length = 0
  } else {
    zip_match_length = zip_MIN_MATCH - 1;
    zip_match_available = 0
  }
  zip_complete = false
}

function zip_deflate_internal(d, b, a) {
  var c;
  if (!zip_initflag) {
    zip_init_deflate();
    zip_initflag = true;
    if (zip_lookahead == 0) {
      zip_complete = true;
      return 0
    }
  }
  if ((c = zip_qcopy(d, b, a)) == a) {
    return a
  }
  if (zip_complete) {
    return c
  }
  if (zip_compr_level <= 3) {
    zip_deflate_fast()
  } else {
    zip_deflate_better()
  } if (zip_lookahead == 0) {
    if (zip_match_available != 0) {
      zip_ct_tally(0, zip_window[zip_strstart - 1] & 255)
    }
    zip_flush_block(1);
    zip_complete = true
  }
  return c + zip_qcopy(d, c + b, a - c)
}

function zip_qcopy(g, e, b) {
  var f, c, a;
  f = 0;
  while (zip_qhead != null && f < b) {
    c = b - f;
    if (c > zip_qhead.len) {
      c = zip_qhead.len
    }
    for (a = 0; a < c; a++) {
      g[e + f + a] = zip_qhead.ptr[zip_qhead.off + a]
    }
    zip_qhead.off += c;
    zip_qhead.len -= c;
    f += c;
    if (zip_qhead.len == 0) {
      var d;
      d = zip_qhead;
      zip_qhead = zip_qhead.next;
      zip_reuse_queue(d)
    }
  }
  if (f == b) {
    return f
  }
  if (zip_outoff < zip_outcnt) {
    c = b - f;
    if (c > zip_outcnt - zip_outoff) {
      c = zip_outcnt - zip_outoff
    }
    for (a = 0; a < c; a++) {
      g[e + f + a] = zip_outbuf[zip_outoff + a]
    }
    zip_outoff += c;
    f += c;
    if (zip_outcnt == zip_outoff) {
      zip_outcnt = zip_outoff = 0
    }
  }
  return f
}

function zip_ct_init() {
  var e;
  var c;
  var b;
  var a;
  var d;
  if (zip_static_dtree[0].dl != 0) {
    return
  }
  zip_l_desc.dyn_tree = zip_dyn_ltree;
  zip_l_desc.static_tree = zip_static_ltree;
  zip_l_desc.extra_bits = zip_extra_lbits;
  zip_l_desc.extra_base = zip_LITERALS + 1;
  zip_l_desc.elems = zip_L_CODES;
  zip_l_desc.max_length = zip_MAX_BITS;
  zip_l_desc.max_code = 0;
  zip_d_desc.dyn_tree = zip_dyn_dtree;
  zip_d_desc.static_tree = zip_static_dtree;
  zip_d_desc.extra_bits = zip_extra_dbits;
  zip_d_desc.extra_base = 0;
  zip_d_desc.elems = zip_D_CODES;
  zip_d_desc.max_length = zip_MAX_BITS;
  zip_d_desc.max_code = 0;
  zip_bl_desc.dyn_tree = zip_bl_tree;
  zip_bl_desc.static_tree = null;
  zip_bl_desc.extra_bits = zip_extra_blbits;
  zip_bl_desc.extra_base = 0;
  zip_bl_desc.elems = zip_BL_CODES;
  zip_bl_desc.max_length = zip_MAX_BL_BITS;
  zip_bl_desc.max_code = 0;
  b = 0;
  for (a = 0; a < zip_LENGTH_CODES - 1; a++) {
    zip_base_length[a] = b;
    for (e = 0; e < (1 << zip_extra_lbits[a]); e++) {
      zip_length_code[b++] = a
    }
  }
  zip_length_code[b - 1] = a;
  d = 0;
  for (a = 0; a < 16; a++) {
    zip_base_dist[a] = d;
    for (e = 0; e < (1 << zip_extra_dbits[a]); e++) {
      zip_dist_code[d++] = a
    }
  }
  d >>= 7;
  for (; a < zip_D_CODES; a++) {
    zip_base_dist[a] = d << 7;
    for (e = 0; e < (1 << (zip_extra_dbits[a] - 7)); e++) {
      zip_dist_code[256 + d++] = a
    }
  }
  for (c = 0; c <= zip_MAX_BITS; c++) {
    zip_bl_count[c] = 0
  }
  e = 0;
  while (e <= 143) {
    zip_static_ltree[e++].dl = 8;
    zip_bl_count[8]++
  }
  while (e <= 255) {
    zip_static_ltree[e++].dl = 9;
    zip_bl_count[9]++
  }
  while (e <= 279) {
    zip_static_ltree[e++].dl = 7;
    zip_bl_count[7]++
  }
  while (e <= 287) {
    zip_static_ltree[e++].dl = 8;
    zip_bl_count[8]++
  }
  zip_gen_codes(zip_static_ltree, zip_L_CODES + 1);
  for (e = 0; e < zip_D_CODES; e++) {
    zip_static_dtree[e].dl = 5;
    zip_static_dtree[e].fc = zip_bi_reverse(e, 5)
  }
  zip_init_block()
}

function zip_init_block() {
  var a;
  for (a = 0; a < zip_L_CODES; a++) {
    zip_dyn_ltree[a].fc = 0
  }
  for (a = 0; a < zip_D_CODES; a++) {
    zip_dyn_dtree[a].fc = 0
  }
  for (a = 0; a < zip_BL_CODES; a++) {
    zip_bl_tree[a].fc = 0
  }
  zip_dyn_ltree[zip_END_BLOCK].fc = 1;
  zip_opt_len = zip_static_len = 0;
  zip_last_lit = zip_last_dist = zip_last_flags = 0;
  zip_flags = 0;
  zip_flag_bit = 1
}

function zip_pqdownheap(a, c) {
  var b = zip_heap[c];
  var d = c << 1;
  while (d <= zip_heap_len) {
    if (d < zip_heap_len && zip_SMALLER(a, zip_heap[d + 1], zip_heap[d])) {
      d++
    }
    if (zip_SMALLER(a, b, zip_heap[d])) {
      break
    }
    zip_heap[c] = zip_heap[d];
    c = d;
    d <<= 1
  }
  zip_heap[c] = b
}

function zip_gen_bitlen(k) {
  var r = k.dyn_tree;
  var d = k.extra_bits;
  var a = k.extra_base;
  var l = k.max_code;
  var p = k.max_length;
  var q = k.static_tree;
  var i;
  var b, c;
  var o;
  var g;
  var j;
  var e = 0;
  for (o = 0; o <= zip_MAX_BITS; o++) {
    zip_bl_count[o] = 0
  }
  r[zip_heap[zip_heap_max]].dl = 0;
  for (i = zip_heap_max + 1; i < zip_HEAP_SIZE; i++) {
    b = zip_heap[i];
    o = r[r[b].dl].dl + 1;
    if (o > p) {
      o = p;
      e++
    }
    r[b].dl = o;
    if (b > l) {
      continue
    }
    zip_bl_count[o]++;
    g = 0;
    if (b >= a) {
      g = d[b - a]
    }
    j = r[b].fc;
    zip_opt_len += j * (o + g);
    if (q != null) {
      zip_static_len += j * (q[b].dl + g)
    }
  }
  if (e == 0) {
    return
  }
  do {
    o = p - 1;
    while (zip_bl_count[o] == 0) {
      o--
    }
    zip_bl_count[o]--;
    zip_bl_count[o + 1] += 2;
    zip_bl_count[p]--;
    e -= 2
  } while (e > 0);
  for (o = p; o != 0; o--) {
    b = zip_bl_count[o];
    while (b != 0) {
      c = zip_heap[--i];
      if (c > l) {
        continue
      }
      if (r[c].dl != o) {
        zip_opt_len += (o - r[c].dl) * r[c].fc;
        r[c].fc = o
      }
      b--
    }
  }
}

function zip_gen_codes(b, g) {
  var d = new Array(zip_MAX_BITS + 1);
  var c = 0;
  var e;
  var f;
  for (e = 1; e <= zip_MAX_BITS; e++) {
    c = ((c + zip_bl_count[e - 1]) << 1);
    d[e] = c
  }
  for (f = 0; f <= g; f++) {
    var a = b[f].dl;
    if (a == 0) {
      continue
    }
    b[f].fc = zip_bi_reverse(d[a]++, a)
  }
}

function zip_build_tree(f) {
  var i = f.dyn_tree;
  var h = f.static_tree;
  var a = f.elems;
  var b, d;
  var g = -1;
  var c = a;
  zip_heap_len = 0;
  zip_heap_max = zip_HEAP_SIZE;
  for (b = 0; b < a; b++) {
    if (i[b].fc != 0) {
      zip_heap[++zip_heap_len] = g = b;
      zip_depth[b] = 0
    } else {
      i[b].dl = 0
    }
  }
  while (zip_heap_len < 2) {
    var e = zip_heap[++zip_heap_len] = (g < 2 ? ++g : 0);
    i[e].fc = 1;
    zip_depth[e] = 0;
    zip_opt_len--;
    if (h != null) {
      zip_static_len -= h[e].dl
    }
  }
  f.max_code = g;
  for (b = zip_heap_len >> 1; b >= 1; b--) {
    zip_pqdownheap(i, b)
  }
  do {
    b = zip_heap[zip_SMALLEST];
    zip_heap[zip_SMALLEST] = zip_heap[zip_heap_len--];
    zip_pqdownheap(i, zip_SMALLEST);
    d = zip_heap[zip_SMALLEST];
    zip_heap[--zip_heap_max] = b;
    zip_heap[--zip_heap_max] = d;
    i[c].fc = i[b].fc + i[d].fc;
    if (zip_depth[b] > zip_depth[d] + 1) {
      zip_depth[c] = zip_depth[b]
    } else {
      zip_depth[c] = zip_depth[d] + 1
    }
    i[b].dl = i[d].dl = c;
    zip_heap[zip_SMALLEST] = c++;
    zip_pqdownheap(i, zip_SMALLEST)
  } while (zip_heap_len >= 2);
  zip_heap[--zip_heap_max] = zip_heap[zip_SMALLEST];
  zip_gen_bitlen(f);
  zip_gen_codes(i, g)
}

function zip_scan_tree(i, h) {
  var b;
  var f = -1;
  var a;
  var d = i[0].dl;
  var e = 0;
  var c = 7;
  var g = 4;
  if (d == 0) {
    c = 138;
    g = 3
  }
  i[h + 1].dl = 65535;
  for (b = 0; b <= h; b++) {
    a = d;
    d = i[b + 1].dl;
    if (++e < c && a == d) {
      continue
    } else {
      if (e < g) {
        zip_bl_tree[a].fc += e
      } else {
        if (a != 0) {
          if (a != f) {
            zip_bl_tree[a].fc++
          }
          zip_bl_tree[zip_REP_3_6].fc++
        } else {
          if (e <= 10) {
            zip_bl_tree[zip_REPZ_3_10].fc++
          } else {
            zip_bl_tree[zip_REPZ_11_138].fc++
          }
        }
      }
    }
    e = 0;
    f = a;
    if (d == 0) {
      c = 138;
      g = 3
    } else {
      if (a == d) {
        c = 6;
        g = 3
      } else {
        c = 7;
        g = 4
      }
    }
  }
}

function zip_send_tree(i, h) {
  var b;
  var f = -1;
  var a;
  var d = i[0].dl;
  var e = 0;
  var c = 7;
  var g = 4;
  if (d == 0) {
    c = 138;
    g = 3
  }
  for (b = 0; b <= h; b++) {
    a = d;
    d = i[b + 1].dl;
    if (++e < c && a == d) {
      continue
    } else {
      if (e < g) {
        do {
          zip_SEND_CODE(a, zip_bl_tree)
        } while (--e != 0)
      } else {
        if (a != 0) {
          if (a != f) {
            zip_SEND_CODE(a, zip_bl_tree);
            e--
          }
          zip_SEND_CODE(zip_REP_3_6, zip_bl_tree);
          zip_send_bits(e - 3, 2)
        } else {
          if (e <= 10) {
            zip_SEND_CODE(zip_REPZ_3_10, zip_bl_tree);
            zip_send_bits(e - 3, 3)
          } else {
            zip_SEND_CODE(zip_REPZ_11_138, zip_bl_tree);
            zip_send_bits(e - 11, 7)
          }
        }
      }
    }
    e = 0;
    f = a;
    if (d == 0) {
      c = 138;
      g = 3
    } else {
      if (a == d) {
        c = 6;
        g = 3
      } else {
        c = 7;
        g = 4
      }
    }
  }
}

function zip_build_bl_tree() {
  var a;
  zip_scan_tree(zip_dyn_ltree, zip_l_desc.max_code);
  zip_scan_tree(zip_dyn_dtree, zip_d_desc.max_code);
  zip_build_tree(zip_bl_desc);
  for (a = zip_BL_CODES - 1; a >= 3; a--) {
    if (zip_bl_tree[zip_bl_order[a]].dl != 0) {
      break
    }
  }
  zip_opt_len += 3 * (a + 1) + 5 + 5 + 4;
  return a
}

function zip_send_all_trees(b, a, c) {
  var d;
  zip_send_bits(b - 257, 5);
  zip_send_bits(a - 1, 5);
  zip_send_bits(c - 4, 4);
  for (d = 0; d < c; d++) {
    zip_send_bits(zip_bl_tree[zip_bl_order[d]].dl, 3)
  }
  zip_send_tree(zip_dyn_ltree, b - 1);
  zip_send_tree(zip_dyn_dtree, a - 1)
}

function zip_flush_block(a) {
  var c, b;
  var e;
  var f;
  f = zip_strstart - zip_block_start;
  zip_flag_buf[zip_last_flags] = zip_flags;
  zip_build_tree(zip_l_desc);
  zip_build_tree(zip_d_desc);
  e = zip_build_bl_tree();
  c = (zip_opt_len + 3 + 7) >> 3;
  b = (zip_static_len + 3 + 7) >> 3;
  if (b <= c) {
    c = b
  }
  if (f + 4 <= c && zip_block_start >= 0) {
    var d;
    zip_send_bits((zip_STORED_BLOCK << 1) + a, 3);
    zip_bi_windup();
    zip_put_short(f);
    zip_put_short(~f);
    for (d = 0; d < f; d++) {
      zip_put_byte(zip_window[zip_block_start + d])
    }
  } else {
    if (b == c) {
      zip_send_bits((zip_STATIC_TREES << 1) + a, 3);
      zip_compress_block(zip_static_ltree, zip_static_dtree)
    } else {
      zip_send_bits((zip_DYN_TREES << 1) + a, 3);
      zip_send_all_trees(zip_l_desc.max_code + 1, zip_d_desc.max_code + 1, e + 1);
      zip_compress_block(zip_dyn_ltree, zip_dyn_dtree)
    }
  }
  zip_init_block();
  if (a != 0) {
    zip_bi_windup()
  }
}

function zip_ct_tally(e, c) {
  zip_l_buf[zip_last_lit++] = c;
  if (e == 0) {
    zip_dyn_ltree[c].fc++
  } else {
    e--;
    zip_dyn_ltree[zip_length_code[c] + zip_LITERALS + 1].fc++;
    zip_dyn_dtree[zip_D_CODE(e)].fc++;
    zip_d_buf[zip_last_dist++] = e;
    zip_flags |= zip_flag_bit
  }
  zip_flag_bit <<= 1;
  if ((zip_last_lit & 7) == 0) {
    zip_flag_buf[zip_last_flags++] = zip_flags;
    zip_flags = 0;
    zip_flag_bit = 1
  }
  if (zip_compr_level > 2 && (zip_last_lit & 4095) == 0) {
    var a = zip_last_lit * 8;
    var d = zip_strstart - zip_block_start;
    var b;
    for (b = 0; b < zip_D_CODES; b++) {
      a += zip_dyn_dtree[b].fc * (5 + zip_extra_dbits[b])
    }
    a >>= 3;
    if (zip_last_dist < parseInt(zip_last_lit / 2) && a < parseInt(d / 2)) {
      return true
    }
  }
  return (zip_last_lit == zip_LIT_BUFSIZE - 1 || zip_last_dist == zip_DIST_BUFSIZE)
}

function zip_compress_block(g, e) {
  var i;
  var b;
  var c = 0;
  var j = 0;
  var f = 0;
  var h = 0;
  var a;
  var d;
  if (zip_last_lit != 0) {
    do {
      if ((c & 7) == 0) {
        h = zip_flag_buf[f++]
      }
      b = zip_l_buf[c++] & 255;
      if ((h & 1) == 0) {
        zip_SEND_CODE(b, g)
      } else {
        a = zip_length_code[b];
        zip_SEND_CODE(a + zip_LITERALS + 1, g);
        d = zip_extra_lbits[a];
        if (d != 0) {
          b -= zip_base_length[a];
          zip_send_bits(b, d)
        }
        i = zip_d_buf[j++];
        a = zip_D_CODE(i);
        zip_SEND_CODE(a, e);
        d = zip_extra_dbits[a];
        if (d != 0) {
          i -= zip_base_dist[a];
          zip_send_bits(i, d)
        }
      }
      h >>= 1
    } while (c < zip_last_lit)
  }
  zip_SEND_CODE(zip_END_BLOCK, g)
}
var zip_Buf_size = 16;

function zip_send_bits(b, a) {
  if (zip_bi_valid > zip_Buf_size - a) {
    zip_bi_buf |= (b << zip_bi_valid);
    zip_put_short(zip_bi_buf);
    zip_bi_buf = (b >> (zip_Buf_size - zip_bi_valid));
    zip_bi_valid += a - zip_Buf_size
  } else {
    zip_bi_buf |= b << zip_bi_valid;
    zip_bi_valid += a
  }
}

function zip_bi_reverse(c, a) {
  var b = 0;
  do {
    b |= c & 1;
    c >>= 1;
    b <<= 1
  } while (--a > 0);
  return b >> 1
}

function zip_bi_windup() {
  if (zip_bi_valid > 8) {
    zip_put_short(zip_bi_buf)
  } else {
    if (zip_bi_valid > 0) {
      zip_put_byte(zip_bi_buf)
    }
  }
  zip_bi_buf = 0;
  zip_bi_valid = 0
}

function zip_qoutbuf() {
  if (zip_outcnt != 0) {
    var b, a;
    b = zip_new_queue();
    if (zip_qhead == null) {
      zip_qhead = zip_qtail = b
    } else {
      zip_qtail = zip_qtail.next = b
    }
    b.len = zip_outcnt - zip_outoff;
    for (a = 0; a < b.len; a++) {
      b.ptr[a] = zip_outbuf[zip_outoff + a]
    }
    zip_outcnt = zip_outoff = 0
  }
}

function zip_deflate(d, f) {
  var b, e;
  var c, a;
  zip_deflate_data = d;
  zip_deflate_pos = 0;
  if (typeof f == "undefined") {
    f = zip_DEFAULT_LEVEL
  }
  zip_deflate_start(f);
  e = new Array(1024);
  b = "";
  while ((c = zip_deflate_internal(e, 0, e.length)) > 0) {
    for (a = 0; a < c; a++) {
      b += String.fromCharCode(e[a])
    }
  }
  zip_deflate_data = null;
  return b
};
