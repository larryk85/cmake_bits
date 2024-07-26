### ANSI escape sequences
### https://en.wikipedia.org/wiki/ANSI_escape_code

function(bits_regular_expressions which output)
   set(num_re "([0-9]+)")
   set(rgb_re "[0-9]+[:;][0-9]+[:;][0-9]+")
   set(named_re "(black|red|green|yellow|blue|magenta|cyan|white|reset)")
   set(mode_re "(reset_all|bold|dim|italic|underline|blink|reverse|hidden|strikethrough|reset_dim_bold|reset_italic|reset_underline|reset_blink|reset_reverse|reset_hidden|reset_strikethrough)")

   if (${which} STREQUAL "numeric")
      set(${output} "${num_re}" PARENT_SCOPE)
   elseif (${which} STREQUAL "rgb")
      set(${output} "${rgb_re}" PARENT_SCOPE)
   elseif (${which} STREQUAL "named")
      set(${output} "${named_re}" PARENT_SCOPE)
   elseif (${which} STREQUAL "mode")
      set(${output} "${mode_re}" PARENT_SCOPE)
   elseif(${which} STREQUAL "mode_prefix")
      set(${output} "(md:|\\^)" PARENT_SCOPE)
   elseif(${which} STREQUAL "foreground")
      set(${output} "(fg:|\\*)" PARENT_SCOPE)
   elseif(${which} STREQUAL "background")
      set(${output} "(bg:|\\!)" PARENT_SCOPE)
   endif()
endfunction(bits_regular_expressions)

function(bits_re_matches token re output)
   string(REGEX MATCH "${re}" ${output} "${token}")
   if (NOT (${output} STREQUAL ""))
      set(${output} TRUE PARENT_SCOPE)
   else()
      set(${output} FALSE PARENT_SCOPE)
   endif()
endfunction(bits_re_matches)

function(bits_token_matches token output)
   bits_regular_expressions(numeric     num_re)
   bits_regular_expressions(rgb         rgb_re)
   bits_regular_expressions(named       named_re)
   bits_regular_expressions(mode        mode_re)
   bits_regular_expressions(foreground  fg_re)
   bits_regular_expressions(background  bg_re)
   bits_regular_expressions(mode_prefix mp_re)

   set(orig_token "${token}")

   bits_re_matches("${token}" "${fg_re}" fres)
   bits_re_matches("${token}" "${bg_re}" bres)
   bits_re_matches("${token}" "${mp_re}" mpres)

   if (fres)
      set(type "fore")
      string(REGEX REPLACE "${fg_re}" "" token "${token}")
   elseif (bres)
      set(type "back")
      string(REGEX REPLACE "${bg_re}" "" token "${token}")
   elseif(mpres)
      set(type "mode")
      string(REGEX REPLACE "${mp_re}" "" token "${token}")
   else()
      set(ret "str:null:${token}")
   endif()

   if ((NOT ret) AND (NOT type STREQUAL "mode"))
      string(REGEX MATCH "${rgb_re}" ${token} "${token}")
      if (CMAKE_MATCH_0 AND (NOT ret))
         set(ret "rgb:${type}:${CMAKE_MATCH_0}")
      endif()

      string(REGEX MATCH "${num_re}" ${token} "${token}")
      if (CMAKE_MATCH_0 AND (NOT ret))
         set(ret "num:${type}:${CMAKE_MATCH_0}")
      endif()

      string(REGEX MATCH "${named_re}" ${token} "${token}")
      if (CMAKE_MATCH_0 AND (NOT ret))
         set(ret "nam:${type}:${CMAKE_MATCH_0}")
      endif()
   else()
      string(REGEX MATCH "${mode_re}" ${token} "${token}")
      if (CMAKE_MATCH_0 AND (NOT ret) AND (type STREQUAL "mode"))
         set(ret "mod:${type}:${CMAKE_MATCH_0}")
      endif()
   endif()

   if (NOT ret)
      message(FATAL_ERROR "token:[${orig_token}] is not a valid token.\
         Ensure that you are using the correct prefix. \
         (fg or *) for foreground colors, (bg or !) for background colors, and (md: or ^) for modes.
      ")
   endif()

   set(${output} "${ret}" PARENT_SCOPE)
endfunction(bits_token_matches)

function(bits_add_to_code code amount output)
   string(ASCII 27 Esc)
   string(REGEX REPLACE "${Esc}\\\[" "" new_code "${code}")
   string(REGEX MATCH "[0-9]+" id "${code}")
   string(REGEX MATCH "[;m].*" rest "${code}")
   math(EXPR id "${id}+${amount}")
   set(${output} "${Esc}[${id}${rest}" PARENT_SCOPE)
endfunction(bits_add_to_code)

function(bits_named_map token output)
   string(ASCII 27 Esc)

   ### Modes
   set(reset_all           "${Esc}[0m")
   set(bold                "${Esc}[1m")
   set(dim                 "${Esc}[2m")
   set(italic              "${Esc}[3m")
   set(underline           "${Esc}[4m")
   set(blink               "${Esc}[5m")
   set(reverse             "${Esc}[7m")
   set(hidden              "${Esc}[8m")
   set(strikethrough       "${Esc}[9m")
   ### Reset Modes
   set(reset_dim_bold      "${Esc}[22m")
   set(reset_italic        "${Esc}[23m")
   set(reset_underline     "${Esc}[24m")
   set(reset_blink         "${Esc}[25m")
   set(reset_reverse       "${Esc}[27m")
   set(reset_hidden        "${Esc}[28m")
   set(reset_strikethrough "${Esc}[29m")
   ### Colors
   set(black               "${Esc}[30m")
   set(red                 "${Esc}[31m")
   set(green               "${Esc}[32m")
   set(yellow              "${Esc}[33m")
   set(blue                "${Esc}[34m")
   set(magenta             "${Esc}[35m")
   set(cyan                "${Esc}[36m")
   set(white               "${Esc}[37m")
   set(reset               "${Esc}[39m")

   set(${output} "${${token}}" PARENT_SCOPE)
endfunction(bits_named_map)

# Function to check if output is to a terminal with color support
function(bits_detect_color_support result_var)
   # Default to no color support
   set(color_support FALSE)

   # Check for common UNIX-like terminal environment variables
   if(DEFINED ENV{TERM})
      string(FIND "$ENV{TERM}" "xterm" xterm_found)
      string(FIND "$ENV{TERM}" "color" color_found)
      string(FIND "$ENV{TERM}" "ansi" ansi_found)
      string(FIND "$ENV{TERM}" "screen" screen_found)
      string(FIND "$ENV{TERM}" "tmux" tmux_found)
      if (xterm_found GREATER -1 OR color_found GREATER -1 OR ansi_found GREATER -1 OR screen_found GREATER -1 OR tmux_found GREATER -1)
         set(color_support TRUE)
      endif()
   endif()

   # Check for COLORTERM environment variable
   if(DEFINED ENV{COLORTERM})
      set(color_support TRUE)
   endif()

   # Check for Windows Terminal
   if(DEFINED ENV{WT_SESSION})
      set(color_support TRUE)
   endif()

   set(${result_var} ${color_support} PARENT_SCOPE)
endfunction(bits_detect_color_support)

function(bits_format str output)
   bits_regular_expressions(foreground fg_re)
   bits_regular_expressions(background bg_re)
   bits_regular_expressions(mode_prefix mp_re)

   bits_regular_expressions(mode mode_re)
   bits_regular_expressions(numeric num_re)
   bits_regular_expressions(rgb rgb_re)
   bits_regular_expressions(named nam_re)

   set(colors_re "(${fg_re}|${bg_re})(${num_re}|${rgb_re}|${nam_re})")
   set(modes_re "(${mp_re}${mode_re})")

   string(REGEX MATCHALL "${colors_re}|${modes_re}" tokens "${str}")

   string(ASCII 27 Esc)

   foreach(token IN ITEMS ${tokens})
      set(orig_token "${token}")

      bits_token_matches("${token}" token)

      string(SUBSTRING "${token}" 0 3 prefix)
      string(SUBSTRING "${token}" 4 4 type)
      string(SUBSTRING "${token}" 9 -1 token)

      if (prefix STREQUAL "nam")
         bits_named_map("${token}" txt)
      elseif (prefix STREQUAL "num")
         set(txt "${Esc}[38;5;${token}m")
      elseif (prefix STREQUAL "rgb")
         string(REGEX REPLACE ":" ";" token "${token}")
         set(txt "${Esc}[38;2;${token}m")
      elseif (prefix STREQUAL "mod")
         bits_named_map("${token}" txt)
      else()
         message(FATAL_ERROR "Invalid token: ${token}")
      endif()

      string(REGEX REPLACE "\\${orig_token}" "${txt}" str "${str}")
   endforeach()

   bits_detect_color_support(color_support)

   if (NOT color_support)
      string(ASCII 27 Esc)
      string(REGEX REPLACE "${Esc}\[(1;)?[0-9]*m" "" str "${str}")
   endif()

   set(${output} "${str}" PARENT_SCOPE)
endfunction(bits_format)

function(bits_cursor_position output)
   if(WIN32)
      execute_process(
         COMMAND powershell -NoProfile -NoLogo -ExecutionPolicy Bypass $host.UI.RawUI.CursorPosition.X
         OUTPUT_VARIABLE cursor_x
         OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      execute_process(
         COMMAND powershell -NoProfile -NoLogo -ExecutionPolicy Bypass $host.UI.RawUI.CursorPosition.Y
         OUTPUT_VARIABLE cursor_y
         OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      set(cursor_position "${cursor_y};${cursor_x}")
   else()
      # based on a script from http://invisible-island.net/xterm/xterm.faq.html"
      set(cursor_pos_script
         "#!/bin/bash /
          exec < /dev/tty
          oldstty=\$(stty -g)
          stty raw -echo min 0
          echo -en \"\\033[6n\" > /dev/tty
          IFS=';' read -r -d R -a pos
          stty \$oldstty
          row=\$((\${pos[0]:2} - 1))
          col=\$((\${pos[1]} - 1))
          echo \"\$col;\$row\""
      )
      file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/bits_cursor_pos.sh" "${cursor_pos_script}")
      execute_process(
         COMMAND bash ${CMAKE_CURRENT_BINARY_DIR}/bits_cursor_pos.sh
         OUTPUT_VARIABLE cursor_position
         OUTPUT_STRIP_TRAILING_WHITESPACE
      )
   endif()
   set(${output} "${cursor_position}" PARENT_SCOPE)
endfunction(bits_cursor_position)

function(bits_set_cursor_position x y)
   string(ASCII 27 Esc)
   message("${Esc}[${y};${x}H")
endfunction(bits_set_cursor_position)

function(bits_formatted_length str length)
   string(ASCII 27 Esc)
   string(REGEX REPLACE "${Esc}\[(1;)?[0-9]*m" "" str "${str}")
   string(LENGTH "${str}" length)
   set(${output} "${length}" PARENT_SCOPE)
endfunction(bits_formatted_length)

function(bits_print message)
   set(options)
   set(oneValueArgs TYPE STYLE)
   set(multiValueArgs)
   cmake_parse_arguments(ARGS "${options}"
                              "${oneValueArgs}"
                              "${multiValueArgs}"
                              ${ARGN})

   bits_format(${message} ${ARGS_STYLE} output)
   if (ARGS_TYPE)
      message(${ARGS_TYPE} "${output}")
   else()
      message("${output}")
   endif()
endfunction(bits_print)

function(bits_reset)
   bits_print("^reset_all")
endfunction(bits_reset)

function(bits_box_style output)
   set(options ROUNDED)
   set(oneValueArgs STYLE)
   set(multiValueArgs)
   cmake_parse_arguments(ARGS "${options}"
                              "${oneValueArgs}"
                              "${multiValueArgs}"
                              ${ARGN})

   if (NOT ARGS_STYLE OR ARGS_STYLE STREQUAL "normal")
      if (ARGS_ROUNDED)
         set(luc "╭")
         set(llc "╰")
         set(ruc "╮")
         set(rlc "╯")
      else()
         set(luc "┌")
         set(llc "└")
         set(ruc "┐")
         set(rlc "┘")
      endif()
      set(hb "─")
      set(vb "│")
   elseif (ARGS_STYLE STREQUAL "thick")
      set(luc "┏")
      set(llc "┗")
      set(ruc "┓")
      set(rlc "┛")
      set(hb "━")
      set(vb "┃")
   elseif (ARGS_STYLE STREQUAL "dashed")
      set(luc "┌")
      set(llc "└")
      set(ruc "┐")
      set(rlc "┘")
      set(hb "╌")
      set(vb "┊")
   elseif (ARGS_STYLE STREQUAL "thick_dashed")
      set(luc "┏")
      set(llc "┗")
      set(ruc "┓")
      set(rlc "┛")
      set(hb "┅")
      set(vb "┇")
   elseif (ARGS_STYLE STREQUAL "dotted")
      set(luc "┌")
      set(llc "└")
      set(ruc "┐")
      set(rlc "┘")
      set(hb "┈")
      set(vb "┊")
   elseif (ARGS_STYLE STREQUAL "thick_dotted")
      set(luc "┏")
      set(llc "┗")
      set(ruc "┓")
      set(rlc "┛")
      set(hb "┉")
      set(vb "┋")
   elseif (ARGS_STYLE STREQUAL "double")
      set(luc "╔")
      set(llc "╚")
      set(ruc "╗")
      set(rlc "╝")
      set(hb "═")
      set(vb "║")
   else()
      message(FATAL_ERROR "Invalid box style: ${ARGS_STYLE}")
   endif()

   set(${output} ${luc} ${llc} ${ruc} ${rlc} ${hb} ${vb} PARENT_SCOPE)
endfunction(bits_box_style)

set(bits_LEFT_UPPER_CORNER  "0")
set(bits_LEFT_LOWER_CORNER  "1")
set(bits_RIGHT_UPPER_CORNER "2")
set(bits_RIGHT_LOWER_CORNER "3")
set(bits_HORIZONTAL_BORDER  "4")
set(bits_VERTICAL_BORDER    "5")

function(bits_box_extras output)
   set(options ROUNDED)
   set(oneValueArgs STYLE)
   set(multiValueArgs)
   cmake_parse_arguments(ARGS "${options}"
                              "${oneValueArgs}"
                              "${multiValueArgs}"
                              ${ARGN})

   if (NOT ARGS_STYLE OR ARGS_STYLE STREQUAL "normal")
      set(tt "┬")
      set(lt "├")
      set(rt "┤")
      set(bt "┴")
      set(c  "┼")
      set(${output} ${tt} ${lt} ${rt} ${bt} ${c} PARENT_SCOPE)
   elseif (ARGS_STYLE STREQUAL "thick")
      set(tt "┳")
      set(lt "┣")
      set(rt "┫")
      set(bt "┻")
      set(c  "╋")
      set(${output} ${tt} ${lt} ${rt} ${bt} ${c} PARENT_SCOPE)
   elseif (ARGS_STYLE STREQUAL "dashed")
      set(tt "┬")
      set(lt "├")
      set(rt "┤")
      set(bt "┴")
      set(c  "┼")
      set(${output} ${tt} ${lt} ${rt} ${bt} ${c} PARENT_SCOPE)
   elseif (ARGS_STYLE STREQUAL "thick_dashed")
      set(tt "┳")
      set(lt "┣")
      set(rt "┫")
      set(bt "┻")
      set(c  "╋")
      set(${output} ${tt} ${lt} ${rt} ${bt} ${c} PARENT_SCOPE)
   elseif (ARGS_STYLE STREQUAL "dotted")
      set(tt "┬")
      set(lt "├")
      set(rt "┤")
      set(bt "┴")
      set(c  "┼")
      set(${output} ${tt} ${lt} ${rt} ${bt} ${c} PARENT_SCOPE)
   elseif (ARGS_STYLE STREQUAL "thick_dotted")
      set(tt "┳")
      set(lt "┣")
      set(rt "┫")
      set(bt "┻")
      set(c  "╋")
      set(${output} ${tt} ${lt} ${rt} ${bt} ${c} PARENT_SCOPE)
   elseif (ARGS_STYLE STREQUAL "double")
      set(tt "╦")
      set(lt "╠")
      set(rt "╣")
      set(bt "╩")
      set(c  "╬")
      set(tt2 "╤")
      set(lt2 "╟")
      set(rt2 "╢")
      set(bt2 "╧")
      set(c2  "╫")
      set(tt3 "╥")
      set(lt3 "╞")
      set(rt3 "╡")
      set(bt3 "╨")
      set(c3  "╬")
      set(${output} ${tt} ${lt} ${rt} ${bt} ${c} ${tt2} ${lt2} ${rt2} ${bt2} ${c2} ${tt3} ${lt3} ${rt3} ${bt3} ${c3} PARENT_SCOPE)
   else()
      message(FATAL_ERROR "Invalid box style: ${ARGS_STYLE}")
   endif()
endfunction(bits_box_extras)

set(bits_TOP_TEE    0)
set(bits_LEFT_TEE   1)
set(bits_RIGHT_TEE  2)
set(bits_BOTTOM_TEE 3)
set(bits_CROSS      4)


function(bits_draw_vertical_line len output)
   set(oneValueArgs STYLE)
   set(multiValueArgs)
   cmake_parse_arguments(ARGS "${options}"
                              "${oneValueArgs}"
                              "${multiValueArgs}"
                              ${ARGN})

   bits_box_style(box_parts STYLE ${ARGS_STYLE})
   list(GET box_parts ${bits_VERTICAL_BORDER} comp)
   set(line "")
   foreach(i RANGE ${len})
      string(APPEND line "${comp}\n")
   endforeach()
   set(${output} "${line}" PARENT_SCOPE)
endfunction(bits_draw_vertical_line)

function(bits_draw_horizontal_line len output)
   set(oneValueArgs STYLE)
   set(multiValueArgs)
   cmake_parse_arguments(ARGS "${options}"
                              "${oneValueArgs}"
                              "${multiValueArgs}"
                              ${ARGN})

   bits_box_style(box_parts STYLE ${ARGS_STYLE})
   list(GET box_parts ${bits_HORIZONTAL_BORDER} comp)
   string(REPEAT "${comp}" ${len} line)
   set(${output} "${line}" PARENT_SCOPE)
endfunction(bits_draw_horizontal_line)

function(bits_draw_box width height output)
   set(options ROUNDED)
   set(oneValueArgs STYLE)
   set(multiValueArgs)
   cmake_parse_arguments(ARGS "${options}"
                              "${oneValueArgs}"
                              "${multiValueArgs}"
                              ${ARGN})

   math(EXPR width "${width} - 2")
   math(EXPR height "${height} - 2")

   bits_box_style(box_parts STYLE ${ARGS_STYLE})
   list(GET box_parts ${bits_LEFT_UPPER_CORNER} luc)
   list(GET box_parts ${bits_RIGHT_UPPER_CORNER} ruc)
   list(GET box_parts ${bits_LEFT_LOWER_CORNER} llc)
   list(GET box_parts ${bits_RIGHT_LOWER_CORNER} rlc)
   list(GET box_parts ${bits_VERTICAL_BORDER} vb)
   list(GET box_parts ${bits_HORIZONTAL_BORDER} hb)

   bits_draw_horizontal_line(${width} hline STYLE ${ARGS_STYLE})
   #bits_draw_vertical_line(${height} vline STYLE ${ARGS_STYLE})
   string(REPEAT " " ${width} inset)

   set(top "${luc}${hline}${ruc}")
   set(bottom "${llc}${hline}${rlc}")
   set(body "")


   foreach(i RANGE ${height})
      string(APPEND body "${vb}${inset}${vb}\n")
   endforeach()
   set(box "${top}\n${body}${bottom}")
   set(${output} "${box}" PARENT_SCOPE)
endfunction(bits_draw_box)

function(bits_center_text msg length output)
   string(LENGTH "${msg}" msg_len)
   math(EXPR total_padding "${length} - ${msg_len}")
   math(EXPR left_padding "${total_padding} / 2")
   math(EXPR right_padding "${total_padding} - ${left_padding}")

   string(REPEAT " " ${left_padding} left_padding_str)
   string(REPEAT " " ${right_padding} right_padding_str)
   set(${output} "${left_padding_str}${msg}${right_padding_str}" PARENT_SCOPE)
endfunction(bits_center_text)


function(bits_options_print)
   set(options)
   set(oneValueArgs)
   set(multiValueArgs OPTIONS)
   cmake_parse_arguments(ARGS "${options}"
                              "${oneValueArgs}"
                              "${multiValueArgs}"
                              ${ARGN})

   set(orig_version_str "^bold^^blue^^italic^${PROJECT_NAME} ^reset^^yellow^v${${PROJECT_NAME}_VERSION}^reset^")
   bits_fmt(version_str "${orig_version_str}")
   bits_remove_ansi_escapes(clean_version_str "${version_str}")
   string(LENGTH "${clean_version_str}" version_str_len)

   set(longest_opt_len 0)
   foreach(option IN LISTS ARGS_OPTIONS)
      string(LENGTH "${option}" opt_len)
      if (opt_len GREATER longest_opt_len)
         set(longest_opt_len ${opt_len})
      endif()
   endforeach()

   math(EXPR full_length "${longest_opt_len} + 20")
   math(EXPR text_length "${full_length} - 11")

   string(REPEAT "─" ${version_str_len} version_border)
   string(REPEAT "─" 6 status_border)
   set(version_title "╭┤${version_str}╞")
   math(EXPR version_title_len "${version_str_len}+3")
   set(status_title "╡^bold_cyan^status^reset^├╮")
   bits_fmt(status_title "${status_title}")
   set(status_title_len 8)

   math(EXPR partial_sum "${version_str_len} + 3 + ${status_title_len}")
   math(EXPR diff_len "${full_length} - ${partial_sum}")

   string(REPEAT "═" ${diff_len} diff_str)
   set(main_title "${version_title}${diff_str}${status_title}")

   string(REPEAT " " ${diff_len} diff_str)
   message(STATUS " ╭${version_border}╮${diff_str}╭${status_border}╮")
   message(STATUS "${main_title}")
   message(STATUS "│╰${version_border}╯${diff_str}╰${status_border}╯│")

   string(REPEAT "═" ${text_length} left_bar)
   string(REPEAT "═" 9 right_bar)
   message(STATUS "╞${left_bar}╦${right_bar}╡")

   macro(print_option option)
      bits_center_text(option_str "${option}" ${text_length})
      if (${${option}})
         set(status_value "✅")
         bits_center_text(status_value "${status_value}" 10)
         bits_fmt(status_value "^bg_bold_green^ ${status_value}^reset^")
         bits_fmt(option_str "^green^^dim^${option_str} ^reset^")
         message(STATUS "│${option_str}║${status_value}│")
      else()
         set(status_value "❌")
         bits_center_text(status_value "${status_value}" 10)
         bits_fmt(status_value "^dim^^bg_bold_red^ ${status_value}^reset^")
         bits_fmt(option_str "^red^^dim^^strikethrough^${option_str} ^reset^")
         message(STATUS "│${option_str}║${status_value}│")
      endif()
   endmacro(print_option)

   list(LENGTH ARGS_OPTIONS options_length)
   math(EXPR last_options_index "${options_length} - 2")
   foreach(index RANGE 0 ${last_options_index})
      list(GET ARGS_OPTIONS ${index} option)
      print_option(${option})
      message(STATUS "╞${left_bar}╬${right_bar}╡")
   endforeach()

   math(EXPR last_options_index "${options_length} - 1")
   list(GET ARGS_OPTIONS ${last_options_index} option)
   print_option(${option})
   message(STATUS "╞${left_bar}╩${right_bar}╡")

   string(REPEAT "─" ${text_length} left_bar)
   string(REPEAT "─" 9 right_bar)
   message(STATUS "╰${left_bar}─${right_bar}╯")
endfunction(bits_options_print)