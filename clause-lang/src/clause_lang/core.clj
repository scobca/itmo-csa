(ns clause-lang.core)

(defn init
  "Basic function after creating project"
  [name]
  (str "Hello, " name "! Welcome to Clause-Lang Core."))

(print (init "scobca"))