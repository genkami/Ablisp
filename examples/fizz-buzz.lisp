(defun fizz-buzz (n)
  (cond
    ((eqv? 0 (% n 15)) "Fizz Buzz")
    ((eqv? 0 (% n 3)) "Fizz")
    ((eqv? 0 (% n 5)) "Buzz")
    (else (object->text n))))

(map (lambda (i)
       (echo (fizz-buzz i)))
     (iota 1 101))
