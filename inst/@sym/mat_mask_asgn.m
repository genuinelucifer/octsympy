%% Copyright (C) 2014 Colin B. Macdonald
%%
%% This file is part of OctSymPy.
%%
%% OctSymPy is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published
%% by the Free Software Foundation; either version 3 of the License,
%% or (at your option) any later version.
%%
%% This software is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty
%% of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
%% the GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public
%% License along with this software; see the file COPYING.
%% If not, see <http://www.gnu.org/licenses/>.

%% -*- texinfo -*-
%% @defun mat_mask_asgn (@var{A}, @var{I}, @var{rhs})
%% Private helper routine for symbolic array assignment via mask.
%%
%% @end defun

%% Author: Colin B. Macdonald
%% Keywords: symbolic

function z = mat_mask_asgn(A, I, B)

  if (~islogical(I))
    error('subscript indices must be either positive integers or logicals')
  end
  if (numel(A) ~= numel(I))
    error('size A not compatible w/ size I in A(I)')
  end

  % issue #18 fix a(t/f)=6
  if (isscalar(A))
    if (I)
      z = B;
    else
      z = A;
    end
    return
  end

  % this messes with the later sanity checks
  if (nnz(I) == 0)
    z = A;
    return
  end


  if (numel(B) == 1)
    B = B*ones(nnz(I),1);
  end
  if (nnz(I) ~= numel(B))
    error('not enough/too much in B')
  end

  if (~(is_same_shape(A,I)))
    % this is not an error, but quite likely reflects a user error
    warning('OctSymPy:subsagn:index_matrix_not_same_shape', ...
            'A and I in A(I) not same shape: no problem, but did you intend this?')
  end
  if (~isvector(B))
    % Here B is a matrix.  B scalar is dealt with earlier.  This is a bit
    % odd (although ok in octave) so probably a user error.
    assert (~isscalar(B))
    warning('OctSymPy:subsagn:rhs_shape', ...
            'B neither vector nor scalar in indexed A(I)=B: unusual, did you intend this?')
  end

  % I think .T makes a copy, but be careful: in general may need a
  % .copy() here
  cmd = { '(A, mask, B) = _ins'
          '# transpose b/c SymPy is row-based'
          'AT = A.T'
          'maskT = mask.T'
          'BT = B.T'
          'j = 0'
          'for i in range(0, len(A)):'
          '    if maskT[i]:'
          '        AT[i] = BT[j]'
          '        j = j + 1'
          'return AT.T,' };

  z = python_cmd (cmd, sym(A), sym(I), sym(B));
end


%% Note: tests in @sym/private/ not executed
% To run these in the test suite, you could move this mfile up to @sym.
% However, note these are generally tested elsewhere indirectly.

%% 2D arrays
%!shared a, b, I
%! b = [1:4]; b = [b; 3*b; 5*b];
%! a = sym(b);
%! I = rand(size(b)) > 0.5;

%!test
%! A = mat_mask_asgn(a,I, 2*b(I));
%! B = b;  B(I) = 2*b(I);
%! assert (isequal (A, B))

%!test
%! % scalar RHS
%! A = mat_mask_asgn(a,I, 17);
%! B = b;  B(I) = 17;
%! assert (isequal (A, B))
