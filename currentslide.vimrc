"""
" Copyright (C) 2009  Yves Frederix
" 
"     This program is free software: you can redistribute it and/or modify
"     it under the terms of the GNU General Public License as published by
"     the Free Software Foundation, either version 3 of the License, or
"     (at your option) any later version.
" 
"     This program is distributed in the hope that it will be useful,
"     but WITHOUT ANY WARRANTY; without even the implied warranty of
"     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"     GNU General Public License for more details.
" 
"     You should have received a copy of the GNU General Public License
"     along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
"
" This VIM extension is meant for usage with the Latex Beamer class
" (http://latex-beamer.sourceforge.net/) When typesetting a single slide, while
" having a large number of total slides, the total compilation process can take a
" very long time. This is not very efficient when you want to fine tune a
" single slide.
" 
" The method compilecurrentslide() below extracts _only_ the latex code
" belonging to the current frame and compiles the resulting code into a pdf,
" hence reducing waiting time. 
"
" Usage:
"   - The method could be mapped to a key stroke
"
"      :map <S-f7> :python compilecurrentslide()<CR>
"
" Features/Limitations/Prereqs:
"   - the resulting pdf is called 'currentslide.pdf' and is written in de
"     current working directory.
"   - Compilation is done using 'pdflatex'
"   - You will need vim compiled with the "+python" option (in Debian/Ubuntu
"     vim-python)
"
"""

map <S-f7> :python compilecurrentslide()<CR>

python << EOF
def compilecurrentslide():
    outfile = 'currentslide.pdf'
    code = getcurrentslidecode()
    result = compilepdf(code, outfile=outfile)
    if result == 0:
        print 'Successfully created %s!' % outfile
    else:
        print 'Error creating pdf...!'

def getcurrentslidecode():
    import vim
    buffer = vim.current.buffer
    nolines = len(buffer)
    currentline, col = vim.current.window.cursor
    currentline -= 1

    # Extract preamble
    preamble = []
    line = ''
    i = 0
    while not line.strip().startswith(r'\begin{document}') and i < nolines:
        line = buffer[i]
        preamble.append(line)
        i += 1
    start_doc_idx = i

    assert currentline > start_doc_idx

    # Search backward for the start of the current frame
    for lineno in xrange(currentline, -1, -1):
        line = buffer[lineno]
        if line.strip().startswith(r'\begin{frame}'):
            start_idx = lineno
            break
    # Search forward for the end of the current frame
    for lineno in xrange(currentline, len(buffer)):
        line = buffer[lineno]
        if line.strip().startswith(r'\end{frame}'):
            end_idx = lineno
            break
    # Extract code for the current frame
    frame = [ buffer[i] for i in xrange(start_idx, end_idx+1) ]
    # Combine preamble and slide code + append \end{document}
    code = ['%% This file is autogenerated by VIM (getcurrenslidecode())', '']
    code.extend(preamble)
    code.extend(frame)
    code.append(r'\end{document}')
    return code

def compilepdf(code, outfile):
    import os
    pdflatex_command = 'pdflatex -interaction nonstopmode'
    assert outfile[-4:] == '.pdf'
    # Extract basename from outfile
    basename = outfile[0:-4]
    texoutfilename = '%s.tex' % basename
    # Write code to tex file
    texout = open(texoutfilename, 'w')
    for l in code:
        texout.write('%s\n' % l)
    texout.close()
    # Create the pdf
    result = os.system('%s %s && %s %s' % (pdflatex_command, texoutfilename,\
        pdflatex_command, texoutfilename))
    return result
EOF

" vim: filetype=python
