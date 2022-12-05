## Install Dependencies

```elixir
Mix.install([
  {:axon, "~> 0.1.0"},
  {:exla, "~> 0.2.2"},
  {:nx, "~> 0.2.1"},
  {:explorer, "~> 0.2.0"},
  {:req, "~> 0.3.0"},
  {:vega_lite, "~> 0.1.5"},
  {:kino_vega_lite, "~> 0.1.1"}
])
```

## Introduction

In this notebook we are going to use the Pima Indians onset of diabetes dataset. This is a standard machine learning dataset from the UCI Machine Learning repository. It describes patient medical record data for Pima Indians and whether they had an onset of diabetes within five years.

First we will load the data into `Explorer` and take a look. Then we will use `Nx` to prepare our data for training and testing. Finally we will use `Axon` to build a Neural Network and train it with the dataset.

It is a binary classification problem (onset of diabetes as 1 or not as 0). All of the other input variables that describe each patient are also numerical. You can learn more about the dataset [here](https://raw.githubusercontent.com/jbrownlee/Datasets/master/pima-indians-diabetes.names).

## Load the Dataset

First we need to download the data to our machine and then load it into `Explorer`. We first add the column names to the csv so that we can refer to them in the explorer dataframe.

```elixir
%{body: body} =
  Req.get!(
    "https://raw.githubusercontent.com/jbrownlee/Datasets/master/pima-indians-diabetes.data.csv"
  )

filename = "pima_natives_diabetes.csv"

column_names =
  "times_pregnant,plasma_glucose_concentration,diastolic_bp,triceps_skin_thick,two_hr_serum_insulin,bmi,diabetes_pedigree,age,class\r\n"

File.write(filename, column_names <> body)

df = Explorer.DataFrame.from_csv!(filename)
```

Now we can explore the dataset a little to see what is inside!

```elixir
Explorer.DataFrame.dtypes(df)
```

```elixir
Explorer.DataFrame.n_rows(df)
```

Lets calculate the mean of every column and plot it out.

```elixir
defmodule ReduceData do
  def reduce_df(df, series_fun) do
    df
    |> Explorer.DataFrame.to_series()
    |> Enum.map(fn {col_name, col} ->
      %{"x" => col_name, "y" => series_fun.(col)}
    end)
  end
end
```

```elixir
mean_data = ReduceData.reduce_df(df, &Explorer.Series.mean/1)
```

```elixir
VegaLite.new(width: 400, height: 400)
|> VegaLite.data_from_values(mean_data)
|> VegaLite.mark(:bar)
|> VegaLite.encode_field(:x, "x", type: :nominal)
|> VegaLite.encode_field(:y, "y", type: :quantitative)
```

## Prepare the Data

Now lets get our data ready for training. First lets normalize the input data. We will use the min-max scaling technique. For each column we will get the min-max range and then we will divide the column elements by this range. This will get all our data in a range from 0-1 which will facilitate the traning of our model.

```elixir
defmodule NormalData do
  def normalize(df, col_names) do
    df
    |> Explorer.DataFrame.select(col_names)
    |> Explorer.DataFrame.to_series()
    |> Enum.map(fn {col_name, col} ->
      max = Explorer.Series.max(col)
      min = Explorer.Series.min(col)
      range = max - min

      normalize_fun = fn val ->
        (val - min) / range
      end

      {col_name,
       Explorer.Series.subtract(col, min)
       |> Explorer.Series.cast(:float)
       |> Explorer.Series.divide(range), normalize_fun}
    end)
  end
end
```

Here we will normalize the entire dataframe. We will also construct a function to normalize any future data we get before we pass it to our model for a prediction.

```elixir
normal = NormalData.normalize(df, Explorer.DataFrame.names(df))

normal_df =
  normal
  |> Enum.map(fn {col_name, normalized_data, _normalize_fun} ->
    {col_name, normalized_data}
  end)
  |> Explorer.DataFrame.new()

normalize_row_fun = fn row ->
  normalize_funs =
    normal
    |> Enum.filter(fn {col_name, _, _} ->
      col_name in [
        "age",
        "bmi",
        "diabetes_pedigree",
        "diastolic_bp",
        "plasma_glucose_concentration",
        "times_pregnant",
        "triceps_skin_thick",
        "two_hr_serum_insulin"
      ]
    end)
    |> Enum.map(fn {_, _, normalize_fun} ->
      normalize_fun
    end)

  Enum.zip([normalize_funs, Nx.to_flat_list(row)])
  |> Enum.map(fn {normalize_fun, elem} ->
    normalize_fun.(elem)
  end)
  |> Nx.tensor()
end
```

Now let's split our data into a training set and a testing set. This is a common machine learning technique. If we use all the data to train then we have no way to actually evaluate our trained model as it could have just memorized the data set and we want a more robust and generalized model.

```elixir
training_df = Explorer.DataFrame.slice(normal_df, 0, 600)
testing_df = Explorer.DataFrame.slice(normal_df, 600, 168)
```

Right now our data is in an `Explorer` dataframe which provides us an excellent way to explore the data but now we need to convert it to a format suitable for training. We need inputs and outputs.

```elixir
defmodule Convert do
  def to_training_data(df, col_names) do
    col_names
    |> Enum.map(fn name ->
      df[name]
      |> Explorer.Series.to_tensor()
      |> Nx.reshape({:auto, 1})
    end)
    |> Nx.concatenate(axis: 1)
  end
end
```

Our training inputs will be the rows of the dataframe except for the `class` column. this column will be our training output. We will also batch the data used for training the model. Then testing data does not need to be batched.

```elixir
train_input_data =
  training_df
  |> Convert.to_training_data([
    "age",
    "bmi",
    "diabetes_pedigree",
    "diastolic_bp",
    "plasma_glucose_concentration",
    "times_pregnant",
    "triceps_skin_thick",
    "two_hr_serum_insulin"
  ])
  |> Nx.to_batched_list(32)

train_output_data =
  training_df
  |> Convert.to_training_data(["class"])
  |> Nx.to_batched_list(32)

test_input_data =
  testing_df
  |> Convert.to_training_data([
    "age",
    "bmi",
    "diabetes_pedigree",
    "diastolic_bp",
    "plasma_glucose_concentration",
    "times_pregnant",
    "triceps_skin_thick",
    "two_hr_serum_insulin"
  ])

test_output_data =
  testing_df
  |> Convert.to_training_data(["class"])
  |> Nx.as_type({:u, 8})
```

Lets take a quick look at the first batch of training data to make sure everything looks ok.

```elixir
train_input_data
|> List.first()
|> IO.inspect()
|> Nx.to_heatmap()
```

## Model Creation

Now we can create our Neural Network model. Our input will be batched so we leave the first dimension as nil in our `input` layer and each input row has 8 data points correspoding to the columns we used to form our training inputs. Next we add a dense layer with 64 neurons with a `relu` activation function. This function will ultimately decide whether or not a given neuron will fire or not. You can read more about this function [here](https://en.wikipedia.org/wiki/Rectifier_(neural_networks)). We then add a dropout layer with a rate of 0.1. This layer will randomly drop certain neurons during training at the rate specified. This helps to prevent overfitting and you can read more [here](https://machinelearningmastery.com/dropout-for-regularizing-deep-neural-networks/). We then add another dense and dropout layer. Finally we finish off with a dense layer with 1 output and a `sigmoid` activation since our output has 2 choices between 0 and 1. You can learn more about this function [here](https://en.wikipedia.org/wiki/Sigmoid_function).

```elixir
model =
  Axon.input({nil, 8}, "input")
  |> Axon.dense(64, activation: :relu)
  |> Axon.dropout(rate: 0.1)
  |> Axon.dense(32, activation: :relu)
  |> Axon.dropout(rate: 0.1)
  |> Axon.dense(1, activation: :sigmoid)
```

## Training and Evaluating the Model

Now that we have our training and testing inputs and outputs we can run a training loop. `Axon` provides us a really nice api to do this. We create a trainer with a `binary_cross_entropy` loss function. This loss function is used for predicting the probability between two outcomes. We will also use the `adam` optimizer. We will print the accuracy and precision metric during training. Finally we run our model for 2000 epochs.

```elixir
params =
  model
  |> Axon.Loop.trainer(:binary_cross_entropy, :adam)
  |> Axon.Loop.metric(:accuracy)
  |> Axon.Loop.metric(:precision)
  |> Axon.Loop.run(Stream.zip(train_input_data, train_output_data), %{},
    compiler: EXLA,
    epochs: 2000
  )
```

After training we can use the parameters or weights from our training run to make predictions on the test input data.

```elixir
%{prediction: prediction} = Axon.predict(model, params, test_input_data, mode: :train)
```

Now we can see the accuracy of our model. When I ran it I got around 0.75 accuracy. Not too bad!

```elixir
Axon.Metrics.accuracy(test_output_data, prediction)
```

Now lets form a confusion matrix.

```elixir
true_pos = Axon.Metrics.true_positives(test_output_data, prediction) |> Nx.to_number()
true_neg = Axon.Metrics.true_negatives(test_output_data, prediction) |> Nx.to_number()
false_pos = Axon.Metrics.false_positives(test_output_data, prediction) |> Nx.to_number()
false_neg = Axon.Metrics.false_negatives(test_output_data, prediction) |> Nx.to_number()

confusion_matrix_data = [
  %{"predicted" => "true", "ground truth" => "true", "val" => true_pos},
  %{"predicted" => "false", "ground truth" => "false", "val" => true_neg},
  %{"predicted" => "true", "ground truth" => "false", "val" => false_pos},
  %{"predicted" => "false", "ground truth" => "true", "val" => false_neg}
]
```

```elixir
VegaLite.new(width: 400, height: 400)
|> VegaLite.data_from_values(confusion_matrix_data)
|> VegaLite.encode_field(:x, "predicted", type: :nominal)
|> VegaLite.encode_field(:y, "ground truth", type: :nominal)
|> VegaLite.layers([
  VegaLite.new()
  |> VegaLite.mark(:rect)
  |> VegaLite.encode_field(:color, "val", type: :quantitative),
  VegaLite.new()
  |> VegaLite.mark(:text)
  |> VegaLite.encode_field(:text, "val", type: :quantitative)
])
```

We can see that our true negatives and true positives are greater than our false negatives and false positives. Now we can calculate the precision and recall of the model. The `precision` is the ratio between the number of true positives to the sum of the true and false positives. The precision can tell us how reliable the model is a classifying a positive. The `recall` is the ratio between the true positives to the sum of the true positives and false negatives. It measures how many positives were correctly classified. You can read more about the precision, recall and the confusion matrix [here](https://blog.paperspace.com/deep-learning-metrics-precision-recall-accuracy/). Here we are sensitive to incorrectly clasiffiying someone as diabetic we would want to focus on improving our precision while tuning our model.

```elixir
pr_data =
  [
    %{
      "name" => "precision",
      "val" => Axon.Metrics.precision(test_output_data, prediction) |> Nx.to_number()
    },
    %{
      "name" => "recall",
      "val" => Axon.Metrics.recall(test_output_data, prediction) |> Nx.to_number()
    }
  ]
  |> IO.inspect()

VegaLite.new(width: 400, height: 400)
|> VegaLite.data_from_values(pr_data)
|> VegaLite.mark(:bar)
|> VegaLite.encode_field(:x, "name", type: :nominal)
|> VegaLite.encode_field(:y, "val", type: :quantitative)
```

Download this notebook [here](https://karangejo.com/notebooks/Binary_Classification_With_Axon_And_Livebook.livemd)